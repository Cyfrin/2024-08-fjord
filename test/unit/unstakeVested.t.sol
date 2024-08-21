// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract UnstakeVestedTest is FjordStakingBase {
    uint256 streamID;

    function afterSetup() internal override {
        streamID = createStreamAndStake();
    }

    function test_UnstakeVested_DepositNotFound() public {
        vm.expectRevert(FjordStaking.DepositNotFound.selector);
        fjordStaking.unstakeVested(1);
    }

    function test_UnstakeVested_UnstakeEarly() public {
        _addRewardAndEpochRollover(1 ether, 1);

        vm.prank(alice);
        vm.expectRevert(FjordStaking.UnstakeEarly.selector);
        fjordStaking.unstakeVested(streamID);
    }

    function test_UnstakeVested_Instant() public {
        assertEq(SABLIER.getRecipient(streamID), address(fjordStaking));
        uint256 balanceBefore = token.balanceOf(alice);

        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(alice);
        assertEq(activeDeposits.length, 0);
        assertEq(fjordStaking.newStaked(), 0);
        (uint16 epoch,, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(vestedStaked, 0);
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(alice);

        assertEq(totalStaked, 0);
        assertEq(unclaimedRewards, 0);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 0);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 0);
        assertEq(nftData.amount, 0);

        uint256 balanceAfter = token.balanceOf(alice);

        assertEq(SABLIER.getRecipient(streamID), alice);
        //No rewards given
        assertEq(balanceBefore, balanceAfter);

        address streamOwner = fjordStaking.getStreamOwner(streamID);
        assertEq(streamOwner, address(0));
    }

    function test_UnstakeVested_AfterClaimCooldown() public {
        assertEq(SABLIER.getRecipient(streamID), address(fjordStaking));
        uint256 balanceBefore = token.balanceOf(alice);

        _addRewardAndEpochRollover(1 ether, 1);

        vm.warp(vm.getBlockTimestamp() + 7 weeks);

        vm.prank(alice);
        vm.expectEmit();
        emit VestedUnstaked(alice, 1, 10 ether, streamID);
        fjordStaking.unstakeVested(streamID);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(alice);
        assertEq(activeDeposits.length, 0);
        assertEq(fjordStaking.newStaked(), 0);
        (uint16 epoch,, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(vestedStaked, 0);
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(alice);

        assertEq(totalStaked, 0);
        assertEq(unclaimedRewards, 1 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 8);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 0);
        assertEq(nftData.amount, 0);

        uint256 balanceAfter = token.balanceOf(alice);

        assertEq(SABLIER.getRecipient(streamID), alice);
        assertEq(balanceAfter, balanceBefore);
    }
}

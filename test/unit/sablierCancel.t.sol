// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract SablierWithdrawTest is FjordStakingBase {
    uint256 streamID;
    ISablierV2LockupLinear sablier;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function afterSetup() internal override {
        streamID = createStreamAndStake(true);
        sablier = ISablierV2LockupLinear(SABLIER_ADDRESS);
    }

    function test_Sablier_Cancel_DisallowCall() public {
        vm.expectRevert(FjordStaking.CallerDisallowed.selector);
        fjordStaking.onStreamCanceled(streamID, address(this), 0, 0);
    }

    function test_Sablier_Cancel_EmitEvent() public {
        // 7 day passed, creator get back 4 ether from stream, 6 ether left
        vm.warp(vm.getBlockTimestamp() + 7 days);
        vm.expectEmit();
        emit SablierCanceled(alice, streamID, address(this), 4 ether);
        sablier.cancel(streamID);
    }

    function test_Sablier_InvalidStreamOwner() public {
        vm.warp(vm.getBlockTimestamp() + 3 days);
        vm.prank(bob);
        vm.expectRevert();
        sablier.cancel(streamID);
    }

    function test_Saliber_Cancel_Instant() public {
        // 5 day passed, creator get back 6 ether from stream, 4 ether left
        vm.warp(vm.getBlockTimestamp() + 5 days);
        sablier.cancel(streamID);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 1);
        assertEq(lastClaimedEpoch, 0);

        assertEq(fjordStaking.newVestedStaked(), 4 ether);
        assertEq(fjordStaking.newStaked(), 4 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 0 ether);
        assertEq(vestedStaked, 4 ether);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 1);
        assertEq(nftData.amount, 4 ether);
    }

    function test_Saliber_Cancel_Later() public {
        _addRewardAndEpochRollover(1 ether, 1);

        assertEq(fjordStaking.totalStaked(), 10 ether);
        assertEq(fjordStaking.totalVestedStaked(), 10 ether);

        assertEq(sablier.getSender(streamID), address(this));
        // 7 day passed, creator get back 4 ether from stream, 6 ether left
        sablier.cancel(streamID);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));

        assertEq(totalStaked, 6 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 1);

        assertEq(fjordStaking.newVestedStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 0 ether);

        assertEq(fjordStaking.totalStaked(), 6 ether);
        assertEq(fjordStaking.totalVestedStaked(), 6 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 0 ether);
        assertEq(vestedStaked, 6 ether);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 1);
        assertEq(nftData.amount, 6 ether);
    }

    function test_Sablier_Cancel_Immediately() public {
        // This case is super rare and only happen within same block
        vm.expectEmit();
        emit Transfer(address(fjordStaking), alice, streamID);
        sablier.cancel(streamID);
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));

        assertEq(totalStaked, 0 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 0);

        assertEq(fjordStaking.newVestedStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 0 ether);

        assertEq(fjordStaking.totalStaked(), 0 ether);
        assertEq(fjordStaking.totalVestedStaked(), 0 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(staked, 0 ether);
        assertEq(vestedStaked, 0 ether);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 0);
        assertEq(nftData.amount, 0 ether);

        assertEq(sablier.ownerOf(streamID), alice);
    }

    function test_Sablier_Withdraw_From_2_VestedStake_SameEpoch() public {
        uint256 streamID2 = createStreamAndStake(true);
        _addRewardAndEpochRollover(1 ether, 1);
        // sender take back 4 ether
        sablier.cancel(streamID);
        // sender take back 4 ether
        sablier.cancel(streamID2);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));

        assertEq(totalStaked, 12 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 1);

        assertEq(fjordStaking.newVestedStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 0 ether);

        assertEq(fjordStaking.totalStaked(), 12 ether);
        assertEq(fjordStaking.totalVestedStaked(), 12 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 0 ether);
        assertEq(vestedStaked, 12 ether);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 1);
        assertEq(nftData.amount, 6 ether);

        NFTData memory nftData2 = fjordStaking.getStreamData(address(alice), streamID2);
        assertEq(nftData2.epoch, 1);
        assertEq(nftData2.amount, 6 ether);
    }

    function test_Sablier_Withdraw_From_2_VestedStake_DiffEpoch() public {
        _addRewardAndEpochRollover(1 ether, 1);
        uint256 streamID2 = createStreamAndStake(true);

        (uint16 epoch2, uint256 staked2, uint256 vestedStaked2) = fjordStaking.deposits(alice, 2);
        assertEq(epoch2, 2);
        assertEq(staked2, 0 ether);
        assertEq(vestedStaked2, 10 ether);

        vm.warp(vm.getBlockTimestamp() + 2 days);
        // 9 day passed, 2 ether taken back
        sablier.cancel(streamID);
        // 2 day passed, 9 ether taken back
        sablier.cancel(streamID2);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));

        assertEq(totalStaked, 8 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 2);
        assertEq(lastClaimedEpoch, 1);

        assertEq(fjordStaking.newVestedStaked(), 1 ether);
        assertEq(fjordStaking.newStaked(), 1 ether);

        assertEq(fjordStaking.totalStaked(), 8 ether);
        assertEq(fjordStaking.totalVestedStaked(), 8 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 0 ether);
        assertEq(vestedStaked, 8 ether);

        (epoch2, staked2, vestedStaked2) = fjordStaking.deposits(alice, 2);
        assertEq(epoch2, 2);
        assertEq(staked2, 0 ether);
        assertEq(vestedStaked2, 1 ether);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 1);
        assertEq(nftData.amount, 8 ether);

        NFTData memory nftData2 = fjordStaking.getStreamData(address(alice), streamID2);
        assertEq(nftData2.epoch, 2);
        assertEq(nftData2.amount, 1 ether);
    }
}

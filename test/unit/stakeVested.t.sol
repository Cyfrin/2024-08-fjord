// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract StakeVestedTest is FjordStakingBase {
    function test_RevertInvalidStreamID() public {
        vm.expectRevert(FjordStaking.NotAStream.selector);
        fjordStaking.stakeVested(0);
    }

    function test_RevertInvalidAssetonStream() public {
        MockERC20 newToken = new MockERC20("New Fjord", "NFJO", 18);
        deal(address(newToken), address(this), 100 ether);
        uint256 streamID = createStream(newToken, false);
        vm.expectRevert(FjordStaking.InvalidAsset.selector);
        vm.prank(alice);
        fjordStaking.stakeVested(streamID);
    }

    function test_RevertInvalidDepleted() public {
        uint256 streamID = createStream();

        bool isCancelable = fjordStaking.sablier().isCancelable(streamID);
        assertEq(isCancelable, false);

        vm.warp(vm.getBlockTimestamp() + 12 days);

        vm.prank(alice);
        SABLIER.withdrawMax(streamID, alice);

        vm.expectRevert(FjordStaking.NotAWarmStream.selector);
        fjordStaking.stakeVested(streamID);
    }

    function test_RevertInvalidCancelableStream() public {
        uint256 streamID = createStream(bob, token, true);

        vm.warp(vm.getBlockTimestamp() + 1 days);

        vm.prank(alice);
        vm.expectRevert(FjordStaking.StreamNotSupported.selector);
        fjordStaking.stakeVested(streamID);
    }

    function test_Stake_Cancelable_Successful() public {
        uint256 streamID = createStreamAndStake(true);

        assertEq(ISablierV2Lockup(fjordStaking.sablier()).getSender(streamID), address(this));
        assertEq(ISablierV2Lockup(fjordStaking.sablier()).isCancelable(streamID), true);
        assertEq(fjordStaking.authorizedSablierSenders(address(this)), true);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 1);
        assertEq(nftData.amount, 10 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 0);
        assertEq(vestedStaked, 10 ether);

        address streamOwner = fjordStaking.getStreamOwner(streamID);
        assertEq(streamOwner, alice);
    }

    function test_RevertStakeSameNFT() public {
        uint256 streamId = createStreamAndStake();

        vm.startPrank(alice);

        vm.expectRevert("ERC721: transfer from incorrect owner");
        fjordStaking.stakeVested(streamId);

        vm.stopPrank();
    }

    function test_StakeMultipleSameEpoch() public {
        createStreamAndStake();

        createStreamAndStake();

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);

        assertEq(epoch, 1);
        assertEq(staked, 0);
        assertEq(vestedStaked, 20 ether);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));
        // same epoch, can't redeem yet
        assertEq(totalStaked, 0 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 1);
        assertEq(lastClaimedEpoch, 0);
    }

    function test_StakeMultipleDifferentEpoch() public {
        createStreamAndStake();

        _addRewardAndEpochRollover(1 ether, 5);
        assertEq(fjordStaking.currentEpoch(), 6);

        uint256 streamID = createStreamAndStake();

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 6);
        assertEq(nftData.amount, 10 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 6);

        assertEq(epoch, 6);
        assertEq(staked, 0);
        assertEq(vestedStaked, 10 ether);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 10 ether);
        assertEq(unclaimedRewards, 5 ether);
        // epoch 6 not redeem yet
        assertEq(unredeemedEpoch, 6);
        assertEq(lastClaimedEpoch, 5);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract BothStakeScenarios is FjordStakingBase {
    /*
    Scenarios:
    - first stakeVested
    - first stake in same epoch
    - addReward
    */
    function test_BothStake_VestFirst_SameEpoch() public {
        uint256 streamID = createStreamAndStake();
        vm.startPrank(alice);
        fjordStaking.stake(5 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 5 ether);
        assertEq(vestedStaked, 10 ether);

        uint256[] memory activeEpoch = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeEpoch.length, 1);
        assertEq(activeEpoch[0], 1);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 1);
        assertEq(nftData.amount, 10 ether);
        vm.stopPrank();

        assertEq(fjordStaking.totalStaked(), 0 ether);
        assertEq(fjordStaking.totalVestedStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 15 ether);
        assertEq(fjordStaking.newVestedStaked(), 10 ether);

        // Add 15 ether reward
        _addRewardAndEpochRollover(15 ether, 1);

        assertEq(fjordStaking.totalStaked(), 15 ether);
        assertEq(fjordStaking.totalVestedStaked(), 10 ether);
        assertEq(fjordStaking.newStaked(), 0 ether);
        assertEq(fjordStaking.newVestedStaked(), 0 ether);

        // Continue adding 15 ether reward
        _addRewardAndEpochRollover(15 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 3);

        // check user data
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 0 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 0);

        // Trigger redeem
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        (totalStaked, unclaimedRewards, unredeemedEpoch, lastClaimedEpoch) =
            fjordStaking.userData(address(alice));
        assertEq(totalStaked, 15 ether);
        assertEq(unclaimedRewards, 30 ether);
        assertEq(unredeemedEpoch, 3);
        assertEq(lastClaimedEpoch, 2);
    }

    /*
    Scenarios:
    - first stake
    - first stakeVested in same epoch
    - addReward
    */

    function test_BothStake_VestAfter_SameEpoch() public {
        vm.startPrank(alice);
        fjordStaking.stake(5 ether);
        vm.stopPrank();

        uint256 streamID = createStreamAndStake();

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 5 ether);
        assertEq(vestedStaked, 10 ether);

        uint256[] memory activeEpoch = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeEpoch.length, 1);
        assertEq(activeEpoch[0], 1);

        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID);
        assertEq(nftData.epoch, 1);
        assertEq(nftData.amount, 10 ether);

        uint256 streamID2 = createStreamAndStake();
        NFTData memory nftData2 = fjordStaking.getStreamData(address(alice), streamID2);
        assertEq(nftData2.epoch, 1);
        assertEq(nftData2.amount, 10 ether);

        assertEq(fjordStaking.totalStaked(), 0 ether);
        assertEq(fjordStaking.totalVestedStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 25 ether);
        assertEq(fjordStaking.newVestedStaked(), 20 ether);

        // Add 15 ether reward
        _addRewardAndEpochRollover(15 ether, 1);

        assertEq(fjordStaking.totalStaked(), 25 ether);
        assertEq(fjordStaking.totalVestedStaked(), 20 ether);
        assertEq(fjordStaking.newStaked(), 0 ether);
        assertEq(fjordStaking.newVestedStaked(), 0 ether);

        // Continue adding 15 ether reward
        _addRewardAndEpochRollover(15 ether, 1);

        // check user data
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 0 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 0);

        // Trigger redeem
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        (totalStaked, unclaimedRewards, unredeemedEpoch, lastClaimedEpoch) =
            fjordStaking.userData(address(alice));
        assertEq(totalStaked, 25 ether);
        assertEq(unclaimedRewards, 30 ether);
        assertEq(unredeemedEpoch, 3);
        assertEq(lastClaimedEpoch, 2);
    }

    /*
    Scenarios:
    - first stakeVested
    - second stakeVested in the same epoch
    - rollover to new epoch
    - first normal stake
    - second vest stake in same epoch
    */

    function test_BothStake_VestStakeTwice() public {
        // First epoch
        // Stake vest fjo first
        uint256 streamID1 = createStreamAndStake();
        NFTData memory nftData = fjordStaking.getStreamData(address(alice), streamID1);
        assertEq(nftData.epoch, 1);
        assertEq(nftData.amount, 10 ether);

        uint256 streamID2 = createStreamAndStake();
        NFTData memory nftData2 = fjordStaking.getStreamData(address(alice), streamID2);
        assertEq(nftData2.epoch, 1);
        assertEq(nftData2.amount, 10 ether);

        // Stake normal fjo later in the same epoch
        vm.startPrank(alice);
        fjordStaking.stake(5 ether);
        vm.stopPrank();

        uint256[] memory activeEpoch = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeEpoch.length, 1);
        assertEq(activeEpoch[0], 1);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 5 ether);
        assertEq(vestedStaked, 20 ether);

        assertEq(fjordStaking.totalStaked(), 0 ether);
        assertEq(fjordStaking.totalVestedStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 25 ether);
        assertEq(fjordStaking.newVestedStaked(), 20 ether);

        // Add 10 ether reward
        _addRewardAndEpochRollover(10 ether, 1);

        // New epoch
        // Stake fjo first
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Stake vested fjo later in the same epoch
        uint256 streamID3 = createStreamAndStake();
        NFTData memory nftData3 = fjordStaking.getStreamData(address(alice), streamID3);
        assertEq(nftData3.epoch, 2);
        assertEq(nftData3.amount, 10 ether);

        uint256[] memory activeEpoch2 = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeEpoch2.length, 2);
        assertEq(activeEpoch2[0], 1);
        assertEq(activeEpoch2[1], 2);

        assertEq(fjordStaking.totalStaked(), 25 ether);
        assertEq(fjordStaking.totalVestedStaked(), 20 ether);
        assertEq(fjordStaking.newStaked(), 15 ether);
        assertEq(fjordStaking.newVestedStaked(), 10 ether);

        // Check epoch 1 redeemed data
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 25 ether);
        // no reward yet bc epoch 1 have no reward
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 2);
        assertEq(lastClaimedEpoch, 1);

        _addRewardAndEpochRollover(10 ether, 1);

        // trigger redeem
        vm.prank(alice);
        fjordStaking.stake(5 ether);
        // Check epoch 2 redeemed data
        (totalStaked, unclaimedRewards, unredeemedEpoch, lastClaimedEpoch) =
            fjordStaking.userData(address(alice));
        assertEq(totalStaked, 40 ether);
        assertEq(unclaimedRewards, 20 ether);
        assertEq(unredeemedEpoch, 3);
        assertEq(lastClaimedEpoch, 2);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract StakeRewardScenarios is FjordStakingBase {
    function _test_Stake_AddReward_ClaimEarly() private {
        // Epoch 1: Stake 1 ether
        fjordStaking.stake(1 ether);

        // Epoch 1: Alice stake 1 ether
        vm.prank(alice);
        fjordStaking.stake(1 ether);

        // Roll over epoch 2, add reward 1 ether each
        _addRewardAndEpochRollover(1 ether, 2);
        assertEq(fjordStaking.currentEpoch(), 3);

        // Claim Reward Early at epoch 3
        (uint256 rewardAmount, uint256 penaltyAmount) = fjordStaking.claimReward(true);
        assertEq(rewardAmount, 0.5 ether);
        assertEq(penaltyAmount, 0.5 ether);
    }

    function test_Stake_AddReward_ClaimEarly() public {
        _test_Stake_AddReward_ClaimEarly();
    }

    function test_Stake_AddReward_ClaimEarly_AddReward_ClaimEarly() public {
        _test_Stake_AddReward_ClaimEarly();

        // Roll over epoch 1, add reward 1 ether + 0.5 penalty of previous epoch
        _addRewardAndEpochRollover(1 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 4);

        // Continue to claim reward at epoch 3, already claim 1 ether so far, can only claim 0.75 ether
        (uint256 rewardAmount, uint256 penaltyAmount) = fjordStaking.claimReward(true);
        assertEq(rewardAmount, 0.375 ether);
        assertEq(penaltyAmount, 0.375 ether);

        // Alice Claim Reward
        vm.startPrank(alice);
        // First claim: reward 0.875 ether and penalty 0.875 ether
        (rewardAmount, penaltyAmount) = fjordStaking.claimReward(true);
        assertEq(rewardAmount, 0.875 ether);
        assertEq(penaltyAmount, 0.875 ether);
        vm.stopPrank();
    }

    function test_Stake_AddReward_ClaimEarly_AddReward_ClaimFull() public {
        _test_Stake_AddReward_ClaimEarly();

        // Roll over epoch 1, add reward 1 ether + 0.5 penalty of previous epoch
        _addRewardAndEpochRollover(1 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 4);

        // Claim Reward and wait for vesting period
        (uint256 rewardAmount, uint256 penaltyAmount) = fjordStaking.claimReward(false);
        assertEq(rewardAmount, 0);
        assertEq(penaltyAmount, 0);

        // Alice Claim Reward
        vm.startPrank(alice);
        // Claim Reward and wait for vesting period
        (rewardAmount, penaltyAmount) = fjordStaking.claimReward(false);
        assertEq(rewardAmount, 0);
        assertEq(penaltyAmount, 0);
        vm.stopPrank();
    }

    function _test_Stake_AddReward_ClaimFull() private {
        // Epoch 1: Stake 1 ether
        fjordStaking.stake(1 ether);

        // Epoch 1: Alice stake 3 ether
        vm.prank(alice);
        fjordStaking.stake(3 ether);

        assertEq(fjordStaking.totalStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 4 ether);

        // Add Reward
        // Roll over epoch 4, add reward 1 ether each
        _addRewardAndEpochRollover(1 ether, 4);

        assertEq(fjordStaking.currentEpoch(), 5);

        // Claim Reward
        (uint256 rewardAmount, uint256 penaltyAmount) = fjordStaking.claimReward(false);
        assertEq(rewardAmount, 0);
        assertEq(penaltyAmount, 0);

        // Check user data
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 1 ether);
        assertEq(unclaimedRewards, 1 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 4);

        // wait for 3 weeks
        vm.warp(vm.getBlockTimestamp() + 3 weeks);
        _addRewardAndEpochRollover(1 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 9);

        // Complete claim request
        // Claim reward from epoch 1 to 4: total 4 ether over 4 ether staked
        rewardAmount = fjordStaking.completeClaimRequest();
        assertEq(rewardAmount, 1 ether);
    }

    function test_Stake_AddReward_ClaimFull() public {
        _test_Stake_AddReward_ClaimFull();
    }

    function test_Stake_AddReward_ClaimFull_AddReward_ClaimFull() public {
        _test_Stake_AddReward_ClaimFull();

        _addRewardAndEpochRollover(1 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 10);

        // Claim Reward
        fjordStaking.claimReward(false);

        // Alice Claim Reward
        vm.prank(alice);
        fjordStaking.claimReward(false);

        // wait for 3 weeks
        vm.warp(vm.getBlockTimestamp() + 3 weeks);
        _addRewardAndEpochRollover(1 ether, 1);

        // Complete claim request
        // Claim reward from epoch 9 to 10: total reward 2 ether over 4 ether total staked
        uint256 rewardAmount = fjordStaking.completeClaimRequest();
        assertEq(rewardAmount, 0.5 ether);

        // Alice complete claim request
        vm.prank(alice);
        // Claim reward from epoch 2 to 10: total reward 6 ether over 4 ether total staked
        // Alice stake amount is 3 ether, reward will be 3/4 * 6
        rewardAmount = fjordStaking.completeClaimRequest();
        assertEq(rewardAmount, 4.5 ether);
    }

    function test_Stake_AddReward_Stake_AddReward() public {
        _test_Stake_AddReward_ClaimFull();
        // Stake 1 ether
        fjordStaking.stake(2 ether);
        uint16 currentEpoch = fjordStaking.currentEpoch();
        (uint16 epoch, uint256 staked,) = fjordStaking.deposits(address(this), currentEpoch);
        assertEq(staked, 2 ether);
        assertEq(epoch, currentEpoch);
        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 2);
        assertEq(activeDeposits[0], 1);
        assertEq(activeDeposits[1], currentEpoch);

        _addRewardAndEpochRollover(1 ether, 3);
        assertEq(fjordStaking.currentEpoch(), currentEpoch + 3);
    }

    function test_Stake_AddReward_ManyTimes() public {
        (uint256 currentTimestamp, uint16 currentEpoch) = (vm.getBlockTimestamp(), 1);
        uint256[] memory depositEpoches = new uint256[](5);
        uint256 totalStake = 0;
        uint256 stakeAmount = 2 ether;
        uint256 totalReward = 0 ether;
        uint256 currentRpt = 0;
        for (uint256 i = 1; i <= 5; i++) {
            fjordStaking.stake(stakeAmount);
            assertEq(fjordStaking.totalStaked(), totalStake);
            totalStake += stakeAmount;
            (uint16 epoch, uint256 staked,) = fjordStaking.deposits(address(this), 1);
            assertEq(staked, stakeAmount);
            assertEq(epoch, 1);
            uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
            assertEq(activeDeposits.length, i);
            depositEpoches[i - 1] = currentEpoch;

            for (uint256 j = 0; j < i; j++) {
                assertEq(activeDeposits[j], depositEpoches[j]);
            }

            for (uint256 j = 0; j < 2; j++) {
                uint256 addedRpt = (1 ether * 1e18 / totalStake);
                currentTimestamp += 1 weeks;
                vm.warp(currentTimestamp);
                vm.prank(minter);
                fjordStaking.addReward(1 ether);
                currentEpoch += 1;
                currentRpt += addedRpt;
                totalReward += 1 ether;
            }
        }
    }
}

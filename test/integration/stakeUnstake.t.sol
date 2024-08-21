// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract StakeUnstakeScenarios is FjordStakingBase {
    function _test_Stake_AddRewardToUnlock() private {
        // Epoch 1 stake 1 ether
        fjordStaking.stake(1 ether);

        // Epoch 1 Alice stake 3 ether
        vm.prank(alice);
        fjordStaking.stake(3 ether);

        // Roll over epoch 3, add reward 1 ether each
        _addRewardAndEpochRollover(1 ether, 3);
        // Current epoch is 4
        assertEq(fjordStaking.currentEpoch(), 4);

        // Alice stake 4 ether at epoch 4
        vm.prank(alice);
        fjordStaking.stake(4 ether);

        // Roll over epoch 7, add reward 1 ether each
        _addRewardAndEpochRollover(1 ether, 4);

        // Current epoch is 8
        assertEq(fjordStaking.currentEpoch(), 8);
    }

    function test_Stake_AddRewardToUnlock_Unstake() public {
        _test_Stake_AddRewardToUnlock();
        uint256 balanceBefore = token.balanceOf(address(this));
        // Full unstake
        uint256 total = fjordStaking.unstake(1, 1 ether);
        // Only return principal amount 1 ether
        assertEq(total, 1 ether);
        uint256 balanceAfter = token.balanceOf(address(this));
        assertEq(balanceAfter, balanceBefore + total);

        balanceBefore = token.balanceOf(address(alice));
        vm.prank(alice);
        total = fjordStaking.unstake(1, 2 ether);
        // Only return principal amount 1 ether
        assertEq(total, 2 ether);
        balanceAfter = token.balanceOf(address(alice));
        assertEq(balanceAfter, balanceBefore + total);

        // Check the leftover staking position 1 (1 ether left and new last claimed epoch is 7)
        (uint16 epoch, uint256 staked,) = fjordStaking.deposits(address(alice), 1);
        assertEq(staked, 1 ether);
        assertEq(epoch, 1);
    }

    function test_Stake_AddRewardToUnlock_UnstakeAll() public {
        _test_Stake_AddRewardToUnlock();

        uint256 balanceBefore = token.balanceOf(address(this));
        // unstake all position => Instant claim reward
        (uint256 totalStakedAmount) = fjordStaking.unstakeAll();
        assertEq(totalStakedAmount, 1 ether);
        uint256 balanceAfter = token.balanceOf(address(this));
        assertEq(balanceAfter, balanceBefore + totalStakedAmount);
        // No acitve deposit left
        assertEq(fjordStaking.getActiveDeposits(address(this)).length, 0);

        balanceBefore = token.balanceOf(address(alice));
        vm.prank(alice);
        // Unstake all position, only 1 position is available to unstake => Instant claim reward
        (totalStakedAmount) = fjordStaking.unstakeAll();
        // Only position 1 is unstaked, return 3 ether staked
        assertEq(totalStakedAmount, 3 ether);
        balanceAfter = token.balanceOf(address(alice));
        assertEq(balanceAfter, balanceBefore + totalStakedAmount);

        assertEq(fjordStaking.getActiveDeposits(address(alice)).length, 1);
    }

    function testStake1001Times_Unstake1_UnstakeAll() public {
        (uint256 currentTimestamp, uint16 currentEpoch) = (vm.getBlockTimestamp(), 1);
        for (uint256 i = 0; i < 1001; i++) {
            fjordStaking.stake(1 ether);
            currentTimestamp += 1 weeks;
            vm.warp(currentTimestamp);
            vm.prank(minter);
            fjordStaking.addReward(1 ether);
            currentEpoch += 1;
        }
        (uint256 total) = fjordStaking.unstake(1, 1 ether);
        assertEq(total, 1 ether);

        (uint256 totalStakedAmount) = fjordStaking.unstakeAll();
        assertEq(totalStakedAmount, 1000 ether - 6 ether);
    }

    function testStake1000Times_UnstakeMany() public {
        (uint256 currentTimestamp, uint16 currentEpoch) = (vm.getBlockTimestamp(), 1);
        for (uint256 i = 0; i < 1001; i++) {
            fjordStaking.stake(1 ether);
            currentTimestamp += 1 weeks;
            vm.warp(currentTimestamp);
            vm.prank(minter);
            fjordStaking.addReward(addRewardPerEpoch);
            currentEpoch += 1;
        }

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 1001);

        for (uint16 i = 1; i <= 100; i++) {
            fjordStaking.unstake(i, addRewardPerEpoch);
            activeDeposits = fjordStaking.getActiveDeposits(address(this));
            assertEq(activeDeposits.length, 1001 - i);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract AddReward_Unit_Test is FjordStakingBase {
    uint256 epochReward = 0;

    function afterSetup() internal override {
        fjordStaking.stake(10 ether);

        epochReward = fjordStaking.rewardPerToken(0);
        assertEq(epochReward, 0);

        epochReward = fjordStaking.rewardPerToken(1);
        assertEq(epochReward, 0);
    }

    function test_InvalidMinter() public {
        vm.warp(vm.getBlockTimestamp() + 1 weeks);
        vm.expectRevert(FjordStaking.CallerDisallowed.selector);
        fjordStaking.addReward(1 ether);
    }

    function test_AddZeroReward_InvalidAmount() public {
        vm.startPrank(minter);
        vm.expectRevert(FjordStaking.InvalidAmount.selector);
        fjordStaking.addReward(0);
    }

    function test_AddReward() public {
        // Add 1 ether reward and move to next epoch
        _addRewardAndEpochRollover(1 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 2);
        assertEq(fjordStaking.lastEpochRewarded(), 1);

        // Add another 1 ether reward and move to next epoch
        _addRewardAndEpochRollover(1 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 3);
        assertEq(fjordStaking.lastEpochRewarded(), 2);

        epochReward = fjordStaking.rewardPerToken(2);
        // Total added reward is 2 ether, total staked is 10 ether
        assertEq(epochReward, 2 ether * (1e18) / 10 ether);
    }

    function test_AddReward_WithEpochGap() public {
        // Add 1 ether reward and move to next 6 epochs
        vm.warp(vm.getBlockTimestamp() + 6 weeks);
        vm.prank(minter);
        fjordStaking.addReward(1 ether);
        assertEq(fjordStaking.currentEpoch(), 7);
        assertEq(fjordStaking.lastEpochRewarded(), 6);

        // Check gap epochs rpt equal to 0
        for (uint16 i = 0; i <= 6; i++) {
            epochReward = fjordStaking.rewardPerToken(i);
            assertEq(epochReward, 0);
        }

        // Add another 1 ether reward and move to next 2 epochs
        vm.warp(vm.getBlockTimestamp() + 2 weeks);
        vm.prank(minter);
        fjordStaking.addReward(1 ether);
        assertEq(fjordStaking.currentEpoch(), 9);
        assertEq(fjordStaking.lastEpochRewarded(), 8);
        for (uint16 i = 7; i <= 8; i++) {
            epochReward = fjordStaking.rewardPerToken(i);
            // Total added reward is 2 ether, total staked is 10 ether
            assertEq(epochReward, 2 ether * (1e18) / 10 ether);
        }
    }

    function test_AddReward_EmitRewardAddedEvent() public {
        vm.expectEmit();

        emit Staked(address(this), 1, 1 ether);
        fjordStaking.stake(1 ether);

        vm.warp(vm.getBlockTimestamp() + 1 weeks);
        vm.prank(minter);
        emit RewardAdded(1, minter, 1 ether);
        fjordStaking.addReward(1 ether);

        emit Staked(address(this), 2, 1 ether);
        fjordStaking.stake(1 ether);

        vm.warp(vm.getBlockTimestamp() + 1 weeks);
        vm.prank(minter);
        emit RewardAdded(2, minter, 2 ether);
        fjordStaking.addReward(2 ether);
    }

    function test_AddReward_EmitRewardPerTokenChanged() public {
        vm.expectEmit();

        emit Staked(address(this), 1, 1 ether);
        fjordStaking.stake(1 ether);

        vm.warp(vm.getBlockTimestamp() + 1 weeks);
        vm.prank(minter);
        emit RewardPerTokenChanged(1, 0);
        fjordStaking.addReward(1 ether);

        vm.warp(vm.getBlockTimestamp() + 1 weeks);
        vm.prank(minter);
        emit RewardPerTokenChanged(2, 3 ether);
        fjordStaking.addReward(2 ether);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract ClaimReward_Unit_Test is FjordStakingBase {
    function afterSetup() internal override {
        fjordStaking.stake(10 ether);
    }

    /// @notice staking postion epoch is larger or equal to current epoch
    function test_ClaimReward_ClaimTooEarly() public {
        vm.expectRevert(FjordStaking.ClaimTooEarly.selector);
        fjordStaking.claimReward(false);
    }

    function test_ClaimReward_WaitVestingPeriod() public {
        // Total added reward is 6 ether over 6 epochs
        _addRewardAndEpochRollover(1 ether, 6);
        vm.expectEmit();
        emit ClaimReceiptCreated(address(this), 7);
        (uint256 rewardAmount, uint256 penaltyAmount) = fjordStaking.claimReward(false);
        // No instant reward
        assertEq(rewardAmount, 0);
        assertEq(penaltyAmount, 0);
        // Check receipt for later claim
        (uint16 requestedEpoch, uint256 amount) = fjordStaking.claimReceipts(address(this));
        assertEq(requestedEpoch, 7);
        assertEq(amount, 6 ether);

        // Check user data
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 10 ether);
        assertEq(unclaimedRewards, 6 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 6);
    }

    function test_ClaimReward_Instant() public {
        // Total added reward is 6 ether over 6 epochs
        _addRewardAndEpochRollover(1 ether, 6);
        vm.expectEmit();
        emit EarlyRewardClaimed(address(this), 3 ether, 3 ether);
        (uint256 rewardAmount, uint256 penaltyAmount) = fjordStaking.claimReward(true);
        assertEq(rewardAmount, 3 ether);
        assertEq(penaltyAmount, 3 ether);
        // Check user data
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 10 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 6);
    }

    function test_ClaimReward_NothingToClaim() public {
        _addRewardAndEpochRollover(1 ether, 6);
        fjordStaking.claimReward(true);

        vm.expectRevert(FjordStaking.NothingToClaim.selector);
        fjordStaking.claimReward(false);
    }

    /// @notice last claimed epoch is larger or equal to current epoch
    function test_ClaimReward_ClaimTooEarly_2() public {
        _addRewardAndEpochRollover(1 ether, 2);

        fjordStaking.claimReward(false);
        vm.expectRevert(FjordStaking.ClaimTooEarly.selector);
        fjordStaking.claimReward(false);
    }

    /// @notice have pending claim receipt
    function test_ClaimReward_ClaimTooEarly_3() public {
        _addRewardAndEpochRollover(1 ether, 2);

        fjordStaking.claimReward(false);

        _addRewardAndEpochRollover(1 ether, 2);
        vm.expectRevert(FjordStaking.ClaimTooEarly.selector);
        fjordStaking.claimReward(true);
    }
}

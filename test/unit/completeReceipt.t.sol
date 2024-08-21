// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract CompleteReceipt_Unit_Test is FjordStakingBase {
    function afterSetup() internal override {
        fjordStaking.stake(10 ether);

        // Total added reward is 6 ether over 6 epochs
        _addRewardAndEpochRollover(1 ether, 6);
        fjordStaking.claimReward(false);
        assertEq(fjordStaking.currentEpoch(), 7);
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 10 ether);
        // unclaimed rewards from epoch 1 to 6
        assertEq(unclaimedRewards, 6 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 6);
    }

    function test_CompleteReceipt_ClaimReceiptNotFound() public {
        vm.prank(alice);
        vm.expectRevert(FjordStaking.ClaimReceiptNotFound.selector);
        fjordStaking.completeClaimRequest();
    }

    function test_CompleteReceipt_CompleteRequestTooEarly() public {
        // Current epoch is 7
        // Only can claim at epoch >= 11
        for (uint256 i = 0; i < 3; i++) {
            _addRewardAndEpochRollover(1 ether, 1);
            vm.expectRevert(FjordStaking.CompleteRequestTooEarly.selector);
            fjordStaking.completeClaimRequest();
        }
    }

    function test_CompleteReceipt_Success() public {
        _addRewardAndEpochRollover(1 ether, 4);

        assertEq(fjordStaking.currentEpoch(), 11);

        vm.expectEmit();
        emit RewardClaimed(address(this), 6 ether);
        uint256 balanceBefore = token.balanceOf(address(this));
        uint256 rewardAmount = fjordStaking.completeClaimRequest();
        assertEq(rewardAmount, 6 ether);
        uint256 balanceAfter = token.balanceOf(address(this));
        assertEq(balanceAfter - balanceBefore, 6 ether);
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 10 ether);
        // 4 ether from epoch 7 to 10
        assertEq(unclaimedRewards, 4 ether);
        assertEq(unredeemedEpoch, 0);
        // last updated at 10
        assertEq(lastClaimedEpoch, 10);

        (uint16 requestedEpoch, uint256 amount) = fjordStaking.claimReceipts(address(this));
        assertEq(requestedEpoch, 0);
        assertEq(amount, 0);
    }
}

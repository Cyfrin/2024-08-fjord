// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract BothClaimScenarios is FjordStakingBase {
    /*
    - Both stake same epoch
    - Instant claim instant
    */
    function test_BothClaim_Instant() public {
        createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Add 15 ether reward for 4 epoch
        _addRewardAndEpochRollover(15 ether, 4);
        assertEq(fjordStaking.currentEpoch(), 5);
        vm.prank(alice);
        (uint256 rewardAmount, uint256 penaltyAmount) = fjordStaking.claimReward(true);
        assertEq(rewardAmount, 30 ether);
        assertEq(penaltyAmount, 30 ether);

        // Check user data
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 15 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 4);
    }
    /*
    - Both stake same epoch
    - Wait Claim Wait
    */

    function test_BothClaim_Wait() public {
        createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Add 15 ether reward for 4 epoch
        _addRewardAndEpochRollover(15 ether, 4);
        assertEq(fjordStaking.currentEpoch(), 5);

        vm.prank(alice);
        fjordStaking.claimReward(false);

        // Check user data
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 15 ether);
        // reward added from epoch 1 to 4
        assertEq(unclaimedRewards, 60 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 4);

        _addRewardAndEpochRollover(15 ether, 4);
        assertEq(fjordStaking.currentEpoch(), 9);
        vm.prank(alice);
        uint256 rewardAmount = fjordStaking.completeClaimRequest();
        assertEq(rewardAmount, 60 ether);

        (totalStaked, unclaimedRewards, unredeemedEpoch, lastClaimedEpoch) =
            fjordStaking.userData(address(alice));
        assertEq(totalStaked, 15 ether);
        // reward added from epoch 5 to 8
        assertEq(unclaimedRewards, 60 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 8);
    }
}

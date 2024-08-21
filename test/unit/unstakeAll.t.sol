// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract UnstakeAll_Unit_Test is FjordStakingBase {
    uint256 streamID;

    function afterSetup() internal override {
        fjordStaking.stake(1 ether);
        deal(address(token), address(alice), 100 ether);
    }

    function test_UnstakeAll_NoActiveDeposit() public {
        vm.prank(alice);
        vm.expectRevert(FjordStaking.NoActiveDeposit.selector);
        fjordStaking.unstakeAll();
    }

    function test_Unstake_All() public {
        _addRewardAndEpochRollover(2 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 2);

        // epoch 2 stake new position
        fjordStaking.stake(1 ether);

        _addRewardAndEpochRollover(2 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 3);

        // epoch 3 stake new position
        fjordStaking.stake(2 ether);

        _addRewardAndEpochRollover(2 ether, 6);
        assertEq(fjordStaking.currentEpoch(), 9);

        // epoch 9 stake position
        fjordStaking.stake(1 ether);

        // unstake position epoch 1
        uint256[] memory activeDepositsBefore = fjordStaking.getActiveDeposits(address(this));
        uint256[] memory activeDepositsAfter = new uint256[](2);
        activeDepositsAfter[0] = 9;
        activeDepositsAfter[1] = 3;
        uint256 balanceBefore = token.balanceOf(address(this));

        vm.expectEmit();
        emit UnstakedAll(address(this), 2 ether, activeDepositsBefore, activeDepositsAfter);
        fjordStaking.unstakeAll();

        uint256 balanceAfter = token.balanceOf(address(this));
        assertEq(balanceAfter - balanceBefore, 2 ether);

        assertEq(fjordStaking.totalStaked(), 2 ether);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 2 ether);
        assertEq(unclaimedRewards, 16 ether);
        // epoch 9 can't be redeem yet because unstakeAll still in epoch 9
        assertEq(unredeemedEpoch, 9);
        assertEq(lastClaimedEpoch, 8);
    }

    function test_Unstake_All_Only_Vested_Remain() public {
        _addRewardAndEpochRollover(2 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 2);

        // epoch 2 stake new position
        vm.prank(alice);
        fjordStaking.stake(1 ether);

        _addRewardAndEpochRollover(2 ether, 1);
        assertEq(fjordStaking.currentEpoch(), 3);

        // epoch 3 stake new position
        vm.prank(alice);
        fjordStaking.stake(2 ether);
        streamID = createStreamAndStake();

        _addRewardAndEpochRollover(2 ether, 7);

        // unstake position epoch 1,3, remain vested
        vm.prank(alice);
        fjordStaking.unstakeAll();

        (, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(address(alice), 3);
        assertEq(staked, 0);
        assertEq(vestedStaked, 10 ether);
    }
}

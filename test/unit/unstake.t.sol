// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract Unstake_Unit_Test is FjordStakingBase {
    function afterSetup() internal override {
        fjordStaking.stake(10 ether);
    }

    function test_Unstake_InvalidAmount() public {
        vm.expectRevert(FjordStaking.InvalidAmount.selector);
        fjordStaking.unstake(1, 0);
    }

    function test_Unstake_DepositNotFound() public {
        vm.expectRevert(FjordStaking.DepositNotFound.selector);
        fjordStaking.unstake(2, 1);
    }

    function test_Unstake_UnstakeMoreThanDeposit() public {
        vm.expectRevert(FjordStaking.UnstakeMoreThanDeposit.selector);
        fjordStaking.unstake(1, 10 ether + 1);
    }

    function test_Unstake_UnstakeEarly() public {
        for (uint256 i = 0; i < 6; i++) {
            // Add reward and move to next 1 epoch
            _addRewardAndEpochRollover(1 ether, 1);
            vm.expectRevert(FjordStaking.UnstakeEarly.selector);
            fjordStaking.unstake(1, 10 ether);
        }
        // latest epoch is 7, only unstake after epoch 7
    }

    function test_Unstake_Full_Instant() public {
        // Total added reward is 7 ether over 7 epochs
        _addRewardAndEpochRollover(1 ether, 7);
        assertEq(fjordStaking.currentEpoch(), 8);

        uint256 balanceBefore = token.balanceOf(address(this));

        // 10 ether staked
        vm.expectEmit();
        emit Unstaked(address(this), 1, 10 ether);
        uint256 total = fjordStaking.unstake(1, 10 ether);
        assertEq(total, 10 ether);
        assertEq(fjordStaking.totalStaked(), 0 ether);
        uint256 balanceAfter = token.balanceOf(address(this));
        assertEq(balanceAfter, balanceBefore + 10 ether);

        // Check staking position
        (uint16 epoch, uint256 staked,) = fjordStaking.deposits(address(this), 1);
        assertEq(epoch, 0);
        assertEq(staked, 0);
        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 0);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 0 ether);
        assertEq(unclaimedRewards, 7 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 7);
    }

    function test_Unstake_Partial_Instant() public {
        // Total added reward is 7 ether over 7 epochs
        _addRewardAndEpochRollover(1 ether, 7);

        uint256 balanceBefore = token.balanceOf(address(this));

        // 5 ether unstaked
        vm.expectEmit();
        emit Unstaked(address(this), 1, 5 ether);
        uint256 total = fjordStaking.unstake(1, 5 ether);
        assertEq(total, 5 ether);
        assertEq(fjordStaking.totalStaked(), 5 ether);

        uint256 balanceAfter = token.balanceOf(address(this));
        assertEq(balanceAfter, balanceBefore + 5 ether);

        // Check staking position
        (, uint256 staked,) = fjordStaking.deposits(address(this), 1);
        // 5 ether staked left
        assertEq(staked, 5 ether);
        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 1);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 5 ether);
        assertEq(unclaimedRewards, 7 ether);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 7);
    }
}

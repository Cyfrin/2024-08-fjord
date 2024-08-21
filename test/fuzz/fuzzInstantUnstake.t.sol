// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract TestFuzzStake is FjordStakingBase {
    function afterSetup() internal override {
        deal(address(token), address(bob), 100_000_000_000 ether);
        vm.prank(bob);
        token.approve(address(fjordStaking), 100_000_000_000 ether);
    }

    function testFuzz_UnstakeImmediately(uint256 _amount) public {
        vm.prank(bob);
        fjordStaking.stake(100 ether);
        _addRewardAndEpochRollover(10 ether, 5);
        assertEq(fjordStaking.currentEpoch(), 6);

        _amount = uint64(bound(_amount, 1, 100_000_000 ether));
        vm.startPrank(bob);
        if (_amount == 0) {
            vm.expectRevert(FjordStaking.InvalidAmount.selector);
            fjordStaking.stake(_amount);
        } else {
            fjordStaking.stake(_amount);
            fjordStaking.unstake(6, _amount);
        }
        vm.stopPrank();

        uint256 rpt = fjordStaking.rewardPerToken(5);
        assertEq(rpt, 0.5 ether);
        assertEq(fjordStaking.totalStaked(), 100 ether);
        assertEq(fjordStaking.totalVestedStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 0 ether);
        assertEq(fjordStaking.getActiveDeposits(bob).length, 1);
    }
}

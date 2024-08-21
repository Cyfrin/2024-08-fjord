// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract TestFuzzStake is FjordStakingBase {
    function afterSetup() internal override {
        deal(address(token), address(bob), 100_000_000_000 ether);
        vm.prank(bob);
        token.approve(address(fjordStaking), 100_000_000_000 ether);
    }

    function testFuzz_stake(uint256 _amount) public {
        _amount = bound(_amount, 1, 100_000_000 ether);
        vm.startPrank(bob);
        fjordStaking.stake(_amount);
        vm.stopPrank();
    }
}

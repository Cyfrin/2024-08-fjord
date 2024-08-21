// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract Epoch_Unit_Test is FjordStakingBase {
    function test_Epoch_Get() public {
        assertEq(fjordStaking.currentEpoch(), 1);
        uint256 current = block.timestamp;
        uint256 next = current + fjordStaking.epochDuration();
        vm.warp(next);
        assertEq(fjordStaking.currentEpoch(), 1);
    }
}

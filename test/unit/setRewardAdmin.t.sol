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

    function test_InvalidOwner() public {
        vm.prank(alice);
        vm.expectRevert(FjordStaking.CallerDisallowed.selector);
        fjordStaking.setRewardAdmin(newMinter);
        assertEq(fjordStaking.rewardAdmin(), minter);
    }

    function test_InvalidZeroAddress() public {
        vm.expectRevert(FjordStaking.InvalidZeroAddress.selector);
        fjordStaking.setRewardAdmin(address(0));
        assertEq(fjordStaking.rewardAdmin(), minter);
    }

    function test_SetRewardAdmin() public {
        fjordStaking.setRewardAdmin(newMinter);
        assertEq(fjordStaking.rewardAdmin(), newMinter);
    }
}

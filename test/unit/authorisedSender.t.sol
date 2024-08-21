// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract AuthorisedSender_Unit_Test is FjordStakingBase {
    function test_AddSender_NotOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert(FjordStaking.CallerDisallowed.selector);
        fjordStaking.addAuthorizedSablierSender(alice);
    }

    function test_AddSender() public {
        fjordStaking.addAuthorizedSablierSender(alice);

        assertEq(fjordStaking.authorizedSablierSenders(alice), true);
    }

    function test_RemoveSender() public {
        fjordStaking.addAuthorizedSablierSender(alice);

        fjordStaking.removeAuthorizedSablierSender(alice);

        assertEq(fjordStaking.authorizedSablierSenders(alice), false);
    }

    function test_setOwner_ZeroAddress() public {
        vm.expectRevert(FjordStaking.InvalidZeroAddress.selector);
        fjordStaking.setOwner(address(0));
    }

    function test_setOwner() public {
        fjordStaking.setOwner(address(0x1));
    }
}

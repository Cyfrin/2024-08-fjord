// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract ConstructorTest is FjordStakingBase {
    function test_VerifyConstructor() public {
        FjordStaking _fjordStaking =
            new FjordStaking(address(token), minter, SABLIER_ADDRESS, authorizedSender, points);

        assertEq(_fjordStaking.startTime(), vm.getBlockTimestamp());
        assertEq(_fjordStaking.rewardAdmin(), minter);
        assertEq(_fjordStaking.owner(), address(this));
        assertEq(address(_fjordStaking.fjordToken()), address(token));
        assertEq(_fjordStaking.currentEpoch(), 1);
        assertEq(address(_fjordStaking.sablier()), address(SABLIER_ADDRESS));
        assertEq(_fjordStaking.authorizedSablierSenders(address(this)), true);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract TestFuzzStakeVested is FjordStakingBase {
    function afterSetup() internal override {
        deal(address(token), address(bob), 100_000_000_000 ether);
        vm.prank(bob);
        token.approve(address(fjordStaking), 100_000_000_000 ether);
        fjordStaking.addAuthorizedSablierSender(bob);
    }

    function testFuzz_stakeVested(uint256 _amount) public {
        _amount = uint64(bound(_amount, 1, 100_000_000 ether));
        uint256 streamID = createStream(bob, token, false, _amount);
        vm.startPrank(alice);
        SABLIER.approve(address(fjordStaking), streamID);
        fjordStaking.stakeVested(streamID);
    }
}

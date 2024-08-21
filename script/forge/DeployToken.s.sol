// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "lib/forge-std/src/Script.sol";
import "../../src/FjordToken.sol";

contract FjordTokenScript is Script {
    function run() public {
        vm.startBroadcast();
        FjordToken token = new FjordToken();

        console.log("fjord token", address(token));

        vm.stopBroadcast();
    }
}

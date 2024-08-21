// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

import "lib/forge-std/src/Script.sol";
import { FjordStaking } from "../../src/FjordStaking.sol";
import "../../src/FjordPoints.sol";
import "../../src/FjordAuctionFactory.sol";

contract FjordStakingScript is Script {
    function run() public {
        vm.startBroadcast();

        FjordPoints points = new FjordPoints();

        AuctionFactory factory = new AuctionFactory(address(points));

        FjordStaking staking = new FjordStaking(
            vm.envAddress("FJO_ADDRESS"),
            msg.sender,
            vm.envAddress("SABLIERV2_LOCKUPLINEAR"),
            vm.envAddress("AUTHORIZED_SENDER"),
            address(points)
        );

        points.setStakingContract(address(staking));

        console.log("fjord points", address(points));
        console.log("fjord auction factory", address(factory));
        console.log("fjord staking", address(staking));

        vm.stopBroadcast();
    }
}

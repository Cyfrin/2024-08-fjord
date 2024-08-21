// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

import "lib/forge-std/src/Script.sol";

interface IAuctionFactory {
    function createAuction(
        address auctionToken,
        uint256 biddingTime,
        uint256 totalTokens,
        bytes32 salt
    ) external;
}

contract FjordAuctionScript is Script {
    function run(address auctionFactory, address auctionToken, uint256 biddingTime, uint256 totalTokens) public {
        vm.startBroadcast();
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, msg.sender));

        IAuctionFactory(auctionFactory).createAuction(auctionToken, biddingTime, totalTokens, salt);

        vm.stopBroadcast();
    }
}

// FOUNDRY_PROFILE=optimized forge script script/forge/DeployAuction.s.sol:FjordAuctionScript \
//     0xAuctionFactory \
//     0xAuctionToken \
//     biddingTime \
//     totalTokens \
//     --fork-url "RPC_URL" \
//     --private-key PRIVKEY \
//     --legacy \
//     --broadcast \
//     --verify
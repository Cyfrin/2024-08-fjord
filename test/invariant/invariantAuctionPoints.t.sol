// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

import "../../src/FjordStaking.sol";
import { FjordPoints } from "../../src/FjordPoints.sol";
import "./handler/AuctionHandler.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract InvariantAuctionPoints is Test {
    FjordStaking private fjordStaking;
    FjordPoints private fjordPoints;
    FjordAuction private fjordAuction;
    MockERC20 private token;
    MockERC20 private auctionToken;
    AuctionHandler private auctionHandler;
    uint256 public bidDuration = 86400 * 14;
    uint256 public totalRewardToken;
    address minter = makeAddr("minter");
    address private constant SABLIER_ADDRESS = address(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);

    function setUp() public {
        token = new MockERC20("Fjord", "FJO", 18);
        auctionToken = new MockERC20("Reward XYZ Token", "RXT", 18);
        fjordPoints = new FjordPoints();
        fjordStaking = new FjordStaking(
            address(token), minter, SABLIER_ADDRESS, address(this), address(fjordPoints)
        );
        fjordPoints.setStakingContract(address(fjordStaking));

        totalRewardToken = 100_000 ether;
        fjordAuction = new FjordAuction(
            address(fjordPoints), address(auctionToken), bidDuration, totalRewardToken
        );
        deal(address(auctionToken), address(this), totalRewardToken);
        auctionToken.transfer(address(fjordAuction), totalRewardToken);

        auctionHandler = new AuctionHandler(fjordStaking, fjordAuction);
        targetContract(address(auctionHandler));
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = auctionHandler.bid.selector;
        selectors[1] = auctionHandler.unbid.selector;
        selectors[2] = auctionHandler.auctionEnd.selector;
        selectors[3] = auctionHandler.claimTokens.selector;
        targetSelector(FuzzSelector({ addr: address(auctionHandler), selectors: selectors }));
    }

    /// @dev Invariant test to ensure the total staked tokens match the token balance of the staking contract
    function invariant_TotalTransferredToken() public {
        // Retrieve total staked and new staked values
        (uint256 expectedTotalBiddingAmount, uint256 expectedTotalAuctionTokenTransferred) =
            (auctionHandler.totalBiddingAmount(), auctionHandler.totalAuctionTokenTransferred());
        uint256 givenTotalBiddingAmount = fjordAuction.totalBids();
        uint256 givenCurrentHoldingBidAmount = fjordPoints.balanceOf(address(fjordAuction));
        uint256 givenCurrentHoldingAuctionTokenAmount =
            auctionToken.balanceOf(address(fjordAuction));
        if (fjordAuction.ended()) {
            assertEq(
                givenCurrentHoldingBidAmount,
                0,
                "Invariant: total bid amount should be zero after auction ends"
            );
            assertEq(
                givenCurrentHoldingAuctionTokenAmount,
                totalRewardToken - expectedTotalAuctionTokenTransferred,
                "Invariant: total auction token amount should be zero after auction ends"
            );
        } else {
            assertEq(
                givenTotalBiddingAmount,
                expectedTotalBiddingAmount,
                "Invariant: total bidding amount do not match the token balance of the point contract"
            );
            assertEq(
                givenCurrentHoldingBidAmount,
                expectedTotalBiddingAmount,
                "Invariant: total bidding amount do not match the token balance of the point contract"
            );
        }
    }
}

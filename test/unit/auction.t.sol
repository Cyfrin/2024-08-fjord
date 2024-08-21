// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "forge-std/Test.sol";
import "src/FjordAuction.sol";
import { ERC20BurnableMock } from "../mocks/ERC20BurnableMock.sol";
import { SafeMath } from "lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract TestAuction is Test {
    using SafeMath for uint256;

    FjordAuction public auction;
    ERC20BurnableMock public fjordPoints;
    ERC20BurnableMock public auctionToken;
    address public owner = address(0x1);
    uint256 public biddingTime = 1 weeks;
    uint256 public totalTokens = 1000 ether;

    function setUp() public {
        fjordPoints = new ERC20BurnableMock("FjordPoints", "fjoPTS");
        auctionToken = new ERC20BurnableMock("AuctionToken", "AUCT");
        auction =
            new FjordAuction(address(fjordPoints), address(auctionToken), biddingTime, totalTokens);

        deal(address(auctionToken), address(auction), totalTokens);
    }

    function testInvalidFjordPointsAddress() public {
        vm.expectRevert(FjordAuction.InvalidFjordPointsAddress.selector);
        new FjordAuction(address(0), address(0), 0, 0);
    }

    function testInvalidAuctionTokenAddress() public {
        vm.expectRevert(FjordAuction.InvalidAuctionTokenAddress.selector);
        new FjordAuction(address(fjordPoints), address(0), 0, 0);
    }

    function testNewAuction() public {
        new FjordAuction(address(fjordPoints), address(auctionToken), biddingTime, totalTokens);
    }

    function testBidAuctionEnd() public {
        skip(biddingTime + 1);

        vm.expectRevert(FjordAuction.AuctionAlreadyEnded.selector);
        auction.bid(1);
    }

    function testBid() public {
        address bidder = address(0x2);
        uint256 bidAmount = 100 ether;

        deal(address(fjordPoints), bidder, bidAmount);

        vm.startPrank(bidder);
        fjordPoints.approve(address(auction), bidAmount);
        auction.bid(bidAmount);
        vm.stopPrank();

        assertEq(auction.bids(bidder), bidAmount);
        assertEq(fjordPoints.balanceOf(bidder), 0);
        assertEq(fjordPoints.balanceOf(address(auction)), bidAmount);
    }

    function testUnbidAuctionEnd() public {
        skip(biddingTime + 1);

        vm.expectRevert(FjordAuction.AuctionAlreadyEnded.selector);
        auction.unbid(1);
    }

    function testUnbidNoBids() public {
        vm.expectRevert(FjordAuction.NoBidsToWithdraw.selector);
        auction.unbid(1);
    }

    function testUnbidInvalidAmount() public {
        address bidder = address(0x2);
        uint256 bidAmount = 100 ether;

        deal(address(fjordPoints), bidder, bidAmount);

        vm.startPrank(bidder);
        fjordPoints.approve(address(auction), bidAmount);
        auction.bid(bidAmount);

        vm.expectRevert(FjordAuction.InvalidUnbidAmount.selector);
        auction.unbid(bidAmount + 1);

        vm.stopPrank();
    }

    function testUnbid() public {
        address bidder = address(0x2);
        uint256 bidAmount = 100 ether;
        uint256 unbidAmount = 50 ether;

        deal(address(fjordPoints), bidder, bidAmount);

        vm.startPrank(bidder);
        fjordPoints.approve(address(auction), bidAmount);
        auction.bid(bidAmount);
        auction.unbid(unbidAmount);
        vm.stopPrank();

        assertEq(auction.bids(bidder), bidAmount - unbidAmount);
        assertEq(fjordPoints.balanceOf(bidder), unbidAmount);
        assertEq(fjordPoints.balanceOf(address(auction)), bidAmount - unbidAmount);
    }

    function testAuctionEnd() public {
        address bidder = address(0x2);
        uint256 bidAmount = 100 ether;

        deal(address(fjordPoints), bidder, bidAmount);

        vm.startPrank(bidder);
        fjordPoints.approve(address(auction), bidAmount);
        auction.bid(bidAmount);
        vm.stopPrank();

        skip(biddingTime);

        auction.auctionEnd();

        uint256 expectedMultiplier = totalTokens.mul(1e18).div(bidAmount);
        assertEq(auction.multiplier(), expectedMultiplier);
        assertEq(fjordPoints.balanceOf(address(auction)), 0); // Check if the tokens were burned
    }

    function testClaimEarly() public {
        vm.expectRevert(FjordAuction.AuctionNotYetEnded.selector);
        auction.claimTokens();
    }

    function testClaimNoTokens() public {
        skip(biddingTime);

        auction.auctionEnd();

        vm.expectRevert(FjordAuction.NoTokensToClaim.selector);
        auction.claimTokens();
    }

    function testClaimTokens() public {
        address bidder = address(0x2);
        uint256 bidAmount = 100 ether;

        deal(address(fjordPoints), bidder, bidAmount);

        vm.startPrank(bidder);
        fjordPoints.approve(address(auction), bidAmount);
        auction.bid(bidAmount);
        vm.stopPrank();

        skip(biddingTime);

        auction.auctionEnd();

        vm.prank(bidder);
        auction.claimTokens();

        uint256 expectedTokens = bidAmount.mul(auction.multiplier()).div(1e18);
        assertEq(auctionToken.balanceOf(bidder), expectedTokens);
    }

    function testPrematureAuctionEnd() public {
        vm.expectRevert(FjordAuction.AuctionNotYetEnded.selector);
        auction.auctionEnd();
    }

    function testAuctionAlreadyEnded() public {
        address bidder = address(0x2);
        uint256 bidAmount = 100 ether;

        deal(address(fjordPoints), bidder, bidAmount);

        vm.startPrank(bidder);
        fjordPoints.approve(address(auction), bidAmount);
        auction.bid(bidAmount);
        vm.stopPrank();

        skip(biddingTime);
        auction.auctionEnd();

        vm.expectRevert(FjordAuction.AuctionEndAlreadyCalled.selector);
        auction.auctionEnd();
    }

    function testAuctionEndWithNoBids() public {
        skip(biddingTime);

        uint256 balBefore = auctionToken.balanceOf(auction.owner());
        auction.auctionEnd();
        uint256 balAfter = auctionToken.balanceOf(auction.owner());

        assertEq(auction.ended(), true);
        assertEq(balAfter - balBefore, totalTokens);
    }

    function testUnbidToZero() public {
        address bidder = address(0x2);
        uint256 bidAmount = 100 ether;

        deal(address(fjordPoints), bidder, bidAmount);

        vm.startPrank(bidder);
        fjordPoints.approve(address(auction), bidAmount);
        auction.bid(bidAmount);
        auction.unbid(bidAmount);
        vm.stopPrank();

        assertEq(auction.bids(bidder), 0);
        assertEq(fjordPoints.balanceOf(bidder), bidAmount);
        assertEq(fjordPoints.balanceOf(address(auction)), 0);
    }
}

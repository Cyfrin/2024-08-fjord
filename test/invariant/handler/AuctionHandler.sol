// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../../../src/FjordStaking.sol";
import { FjordAuction, ERC20Burnable } from "../../../src/FjordAuction.sol";
import "forge-std/console2.sol";
import { SafeMath } from "lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

contract AuctionHandler is CommonBase, StdCheats, StdUtils {
    using SafeMath for uint256;

    FjordStaking public fjordStaking;
    FjordAuction public fjordAuction;
    ERC20Burnable public fjordPoints;
    uint256 public totalBiddingAmount;
    uint256 public totalAuctionTokenTransferred;
    address[] public bidders;
    mapping(address => bool) public isBidded;

    /// @dev Maps function names to the number of times they have been called.
    mapping(string func => uint256 calls) public calls;

    /// @dev The total number of calls made to this contract.
    uint256 public totalCalls;

    constructor(FjordStaking _fjordStaking, FjordAuction _fjordAuction) {
        fjordStaking = _fjordStaking;
        fjordAuction = _fjordAuction;
        fjordPoints = _fjordAuction.fjordPoints();
    }

    modifier bypassInvalidAddress(address _user) {
        if (_user == address(fjordAuction)) {
            return;
        }
        if (_user == address(fjordPoints)) {
            return;
        }
        if (_user == address(0)) {
            return;
        }
        _;
    }

    /// @param _timeJumpSeed A fuzzed value needed for generating random time warps.
    modifier adjustTimestamp(uint256 _timeJumpSeed) {
        uint256 timeJump = _bound(_timeJumpSeed, 2 minutes, 1 hours);
        uint256 nextTime = vm.getBlockTimestamp() + timeJump;
        vm.warp(nextTime);
        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory _functionName) {
        calls[_functionName]++;
        totalCalls++;
        _;
    }

    /// @dev records the bidder
    function recordOnBidder(address user) public {
        if (!isBidded[user]) {
            bidders.push(user);
            isBidded[user] = true;
        }
    }

    function getRandomBidder() public view returns (address, bool) {
        if (bidders.length == 0) {
            return (address(0), false);
        }
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        return (bidders[random % bidders.length], true);
    }

    function bid(address _user, uint256 _amount, uint256 _timeJumpSeed)
        public
        instrument("bid")
        adjustTimestamp(_timeJumpSeed)
        bypassInvalidAddress(_user)
    {
        if (block.timestamp > fjordAuction.auctionEndTime()) {
            return;
        }

        recordOnBidder(_user);
        _amount = bound(_amount, 1, 100_000_000 ether);
        deal(address(fjordPoints), _user, _amount);
        vm.startPrank(address(_user));
        fjordPoints.approve(address(fjordAuction), _amount);
        fjordAuction.bid(_amount);
        vm.stopPrank();
        totalBiddingAmount += _amount;
    }

    function unbid(uint256 _amount, uint256 _timeJumpSeed)
        public
        instrument("unbid")
        adjustTimestamp(_timeJumpSeed)
    {
        if (block.timestamp > fjordAuction.auctionEndTime()) {
            return;
        }

        (address bidder, bool isOk) = getRandomBidder();
        if (!isOk) {
            return;
        }
        uint256 biddingAmount = fjordAuction.bids(bidder);
        if (biddingAmount == 0) {
            return;
        }
        _amount = bound(_amount, 1, biddingAmount);
        vm.prank(address(bidder));
        fjordAuction.unbid(_amount);
        totalBiddingAmount -= _amount;
    }

    function auctionEnd(uint256 _timeJumpSeed)
        public
        instrument("auctionEnd")
        adjustTimestamp(_timeJumpSeed)
    {
        if (block.timestamp < fjordAuction.auctionEndTime()) {
            return;
        }
        if (fjordAuction.ended()) {
            return;
        }
        if (fjordAuction.totalBids() == 0) {
            return;
        }
        fjordAuction.auctionEnd();
    }

    function claimTokens(uint256 _timeJumpSeed)
        public
        instrument("claimTokens")
        adjustTimestamp(_timeJumpSeed)
    {
        if (!fjordAuction.ended()) {
            return;
        }
        (address bidder, bool isOk) = getRandomBidder();
        if (!isOk) {
            return;
        }
        uint256 biddingAmount = fjordAuction.bids(bidder);
        if (biddingAmount == 0) {
            return;
        }
        uint256 claimableRewardAmount = biddingAmount.mul(fjordAuction.multiplier()).div(1e18);

        vm.prank(bidder);
        fjordAuction.claimTokens();
        totalAuctionTokenTransferred += claimableRewardAmount;
    }
}

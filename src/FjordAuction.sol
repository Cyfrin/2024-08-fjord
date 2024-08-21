// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { ERC20Burnable } from
    "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { SafeMath } from "lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

/**
 * @title Auction
 * @dev Contract to create auctions where users can bid using FjordPoints.
 */
contract FjordAuction {
    using SafeMath for uint256;

    /**
     * @notice Thrown when the provided FjordPoints address is invalid (zero address).
     */
    error InvalidFjordPointsAddress();

    /**
     * @notice Thrown when the provided auction token address is invalid (zero address).
     */
    error InvalidAuctionTokenAddress();

    /**
     * @notice Thrown when a bid is placed after the auction has already ended.
     */
    error AuctionAlreadyEnded();

    /**
     * @notice Thrown when an attempt is made to end the auction before the auction end time.
     */
    error AuctionNotYetEnded();

    /**
     * @notice Thrown when an attempt is made to end the auction after it has already been ended.
     */
    error AuctionEndAlreadyCalled();

    /**
     * @notice Thrown when a user attempts to claim tokens but has no tokens to claim.
     */
    error NoTokensToClaim();

    /**
     * @notice Thrown when a user attempts to withdraw bids but has no bids placed.
     */
    error NoBidsToWithdraw();

    /**
     * @notice Thrown when a user attempts to withdraw an amount greater than their current bid.
     */
    error InvalidUnbidAmount();

    /// @notice The FjordPoints token contract.
    ERC20Burnable public fjordPoints;

    /// @notice The auction token contract, which will be distributed to bidders.
    IERC20 public auctionToken;

    /// @notice The owner of the auction contract.
    address public owner;

    /// @notice The timestamp when the auction ends.
    uint256 public auctionEndTime;

    /// @notice The total amount of FjordPoints bid in the auction.
    uint256 public totalBids;

    /// @notice The total number of tokens available for distribution in the auction.
    uint256 public totalTokens;

    /// @notice The multiplier used to calculate the amount of auction tokens claimable per FjordPoint bid.
    uint256 public multiplier;

    /// @notice A flag indicating whether the auction has ended.
    bool public ended;

    /// @notice A mapping of addresses to the amount of FjordPoints each has bid.
    mapping(address => uint256) public bids;

    /// @notice Constant
    uint256 public constant PRECISION_18 = 1e18;

    /**
     * @notice Emitted when the auction ends.
     * @param totalBids The total amount of FjordPoints bid in the auction.
     * @param totalTokens The total number of auction tokens available for distribution.
     */
    event AuctionEnded(uint256 totalBids, uint256 totalTokens);

    /**
     * @notice Emitted when a user claims their auction tokens.
     * @param bidder The address of the user claiming tokens.
     * @param amount The amount of auction tokens claimed.
     */
    event TokensClaimed(address indexed bidder, uint256 amount);

    /**
     * @notice Emitted when a user bids before the auction ends.
     * @param bidder The address of the user bidding.
     * @param amount The amount of FjordPoints that the user bid.
     */
    event BidAdded(address indexed bidder, uint256 amount);

    /**
     * @notice Emitted when a user withdraws their bid before the auction ends.
     * @param bidder The address of the user withdrawing their bid.
     * @param amount The amount of FjordPoints withdrawn.
     */
    event BidWithdrawn(address indexed bidder, uint256 amount);

    /**
     * @dev Sets the token contract address and auction duration.
     * @param _fjordPoints The address of the FjordPoints token contract.
     * @param _biddingTime The duration of the auction in seconds.
     * @param _totalTokens The total number of tokens to be auctioned.
     */
    constructor(
        address _fjordPoints,
        address _auctionToken,
        uint256 _biddingTime,
        uint256 _totalTokens
    ) {
        if (_fjordPoints == address(0)) {
            revert InvalidFjordPointsAddress();
        }
        if (_auctionToken == address(0)) {
            revert InvalidAuctionTokenAddress();
        }
        fjordPoints = ERC20Burnable(_fjordPoints);
        auctionToken = IERC20(_auctionToken);
        owner = msg.sender;
        auctionEndTime = block.timestamp.add(_biddingTime);
        totalTokens = _totalTokens;
    }

    /**
     * @notice Places a bid in the auction.
     * @param amount The amount of FjordPoints to bid.
     */
    function bid(uint256 amount) external {
        if (block.timestamp > auctionEndTime) {
            revert AuctionAlreadyEnded();
        }

        bids[msg.sender] = bids[msg.sender].add(amount);
        totalBids = totalBids.add(amount);

        fjordPoints.transferFrom(msg.sender, address(this), amount);
        emit BidAdded(msg.sender, amount);
    }

    /**
     * @notice Allows users to withdraw part or all of their bids before the auction ends.
     * @param amount The amount of FjordPoints to withdraw.
     */
    function unbid(uint256 amount) external {
        if (block.timestamp > auctionEndTime) {
            revert AuctionAlreadyEnded();
        }

        uint256 userBids = bids[msg.sender];
        if (userBids == 0) {
            revert NoBidsToWithdraw();
        }
        if (amount > userBids) {
            revert InvalidUnbidAmount();
        }

        bids[msg.sender] = bids[msg.sender].sub(amount);
        totalBids = totalBids.sub(amount);
        fjordPoints.transfer(msg.sender, amount);
        emit BidWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Ends the auction and calculates claimable tokens for each bidder based on their bid proportion.
     */
    function auctionEnd() external {
        if (block.timestamp < auctionEndTime) {
            revert AuctionNotYetEnded();
        }
        if (ended) {
            revert AuctionEndAlreadyCalled();
        }

        ended = true;
        emit AuctionEnded(totalBids, totalTokens);

        if (totalBids == 0) {
            auctionToken.transfer(owner, totalTokens);
            return;
        }

        multiplier = totalTokens.mul(PRECISION_18).div(totalBids);

        // Burn the FjordPoints held by the contract
        uint256 pointsToBurn = fjordPoints.balanceOf(address(this));
        fjordPoints.burn(pointsToBurn);
    }

    /**
     * @notice Allows users to claim their tokens after the auction has ended.
     */
    function claimTokens() external {
        if (!ended) {
            revert AuctionNotYetEnded();
        }

        uint256 userBids = bids[msg.sender];
        if (userBids == 0) {
            revert NoTokensToClaim();
        }

        uint256 claimable = userBids.mul(multiplier).div(PRECISION_18);
        bids[msg.sender] = 0;

        auctionToken.transfer(msg.sender, claimable);
        emit TokensClaimed(msg.sender, claimable);
    }
}

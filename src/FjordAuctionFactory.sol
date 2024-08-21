// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "./FjordAuction.sol";
import { IERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title AuctionFactory
 * @dev Contract to create Auction contracts.
 */
contract AuctionFactory {
    address public fjordPoints;
    address public owner;

    event AuctionCreated(address indexed auctionAddress);

    error NotOwner();
    error InvalidAddress();

    /**
     * @dev Sets the FjordPoints token contract address.
     * @param _fjordPoints The address of the FjordPoints token contract.
     */
    constructor(address _fjordPoints) {
        if (_fjordPoints == address(0)) revert InvalidAddress();

        fjordPoints = _fjordPoints;
        owner = msg.sender;
    }

    /**
     * @dev Modifier to check if the caller is the owner.
     */
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    function setOwner(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert InvalidAddress();
        owner = _newOwner;
    }

    /**
     * @notice Creates a new auction contract using create2.
     * @param biddingTime The duration of the auction in seconds.
     * @param totalTokens The total number of tokens to be auctioned.
     * @param salt A unique salt for create2 to generate a deterministic address.
     */
    function createAuction(
        address auctionToken,
        uint256 biddingTime,
        uint256 totalTokens,
        bytes32 salt
    ) external onlyOwner {
        address auctionAddress = address(
            new FjordAuction{ salt: salt }(fjordPoints, auctionToken, biddingTime, totalTokens)
        );

        // Transfer the auction tokens from the msg.sender to the new auction contract
        IERC20(auctionToken).transferFrom(msg.sender, auctionAddress, totalTokens);

        emit AuctionCreated(auctionAddress);
    }
}

# FjordAuction
[Git Source](https://github.com/marigoldlabs/fjord-token/blob/e9ab36b35e88b3df615f78df9526e5509e82789f/src/FjordAuction.sol)

*Contract to create auctions where users can bid using FjordPoints.*


## State Variables
### fjordPoints
The FjordPoints token contract.


```solidity
ERC20Burnable public fjordPoints;
```


### auctionToken
The auction token contract, which will be distributed to bidders.


```solidity
IERC20 public auctionToken;
```


### owner
The owner of the auction contract.


```solidity
address public owner;
```


### auctionEndTime
The timestamp when the auction ends.


```solidity
uint256 public auctionEndTime;
```


### totalBids
The total amount of FjordPoints bid in the auction.


```solidity
uint256 public totalBids;
```


### totalTokens
The total number of tokens available for distribution in the auction.


```solidity
uint256 public totalTokens;
```


### multiplier
The multiplier used to calculate the amount of auction tokens claimable per FjordPoint bid.


```solidity
uint256 public multiplier;
```


### ended
A flag indicating whether the auction has ended.


```solidity
bool public ended;
```


### bids
A mapping of addresses to the amount of FjordPoints each has bid.


```solidity
mapping(address => uint256) public bids;
```


### PRECISION_18
Constant


```solidity
uint256 public constant PRECISION_18 = 1e18;
```


## Functions
### constructor

*Sets the token contract address and auction duration.*


```solidity
constructor(
    address _fjordPoints,
    address _auctionToken,
    uint256 _biddingTime,
    uint256 _totalTokens
);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fjordPoints`|`address`|The address of the FjordPoints token contract.|
|`_auctionToken`|`address`||
|`_biddingTime`|`uint256`|The duration of the auction in seconds.|
|`_totalTokens`|`uint256`|The total number of tokens to be auctioned.|


### bid

Places a bid in the auction.


```solidity
function bid(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of FjordPoints to bid.|


### unbid

Allows users to withdraw part or all of their bids before the auction ends.


```solidity
function unbid(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of FjordPoints to withdraw.|


### auctionEnd

Ends the auction and calculates claimable tokens for each bidder based on their bid proportion.


```solidity
function auctionEnd() external;
```

### claimTokens

Allows users to claim their tokens after the auction has ended.


```solidity
function claimTokens() external;
```

## Events
### AuctionEnded
Emitted when the auction ends.


```solidity
event AuctionEnded(uint256 totalBids, uint256 totalTokens);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`totalBids`|`uint256`|The total amount of FjordPoints bid in the auction.|
|`totalTokens`|`uint256`|The total number of auction tokens available for distribution.|

### TokensClaimed
Emitted when a user claims their auction tokens.


```solidity
event TokensClaimed(address indexed bidder, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bidder`|`address`|The address of the user claiming tokens.|
|`amount`|`uint256`|The amount of auction tokens claimed.|

### BidAdded
Emitted when a user bids before the auction ends.


```solidity
event BidAdded(address indexed bidder, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bidder`|`address`|The address of the user bidding.|
|`amount`|`uint256`|The amount of FjordPoints that the user bid.|

### BidWithdrawn
Emitted when a user withdraws their bid before the auction ends.


```solidity
event BidWithdrawn(address indexed bidder, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bidder`|`address`|The address of the user withdrawing their bid.|
|`amount`|`uint256`|The amount of FjordPoints withdrawn.|

## Errors
### InvalidFjordPointsAddress
Thrown when the provided FjordPoints address is invalid (zero address).


```solidity
error InvalidFjordPointsAddress();
```

### InvalidAuctionTokenAddress
Thrown when the provided auction token address is invalid (zero address).


```solidity
error InvalidAuctionTokenAddress();
```

### AuctionAlreadyEnded
Thrown when a bid is placed after the auction has already ended.


```solidity
error AuctionAlreadyEnded();
```

### AuctionNotYetEnded
Thrown when an attempt is made to end the auction before the auction end time.


```solidity
error AuctionNotYetEnded();
```

### AuctionEndAlreadyCalled
Thrown when an attempt is made to end the auction after it has already been ended.


```solidity
error AuctionEndAlreadyCalled();
```

### NoTokensToClaim
Thrown when a user attempts to claim tokens but has no tokens to claim.


```solidity
error NoTokensToClaim();
```

### NoBidsToWithdraw
Thrown when a user attempts to withdraw bids but has no bids placed.


```solidity
error NoBidsToWithdraw();
```

### InvalidUnbidAmount
Thrown when a user attempts to withdraw an amount greater than their current bid.


```solidity
error InvalidUnbidAmount();
```


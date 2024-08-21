# AuctionFactory
[Git Source](https://github.com/marigoldlabs/fjord-token/blob/e9ab36b35e88b3df615f78df9526e5509e82789f/src/FjordAuctionFactory.sol)

*Contract to create Auction contracts.*


## State Variables
### fjordPoints

```solidity
address public fjordPoints;
```


### owner

```solidity
address public owner;
```


## Functions
### constructor

*Sets the FjordPoints token contract address.*


```solidity
constructor(address _fjordPoints);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fjordPoints`|`address`|The address of the FjordPoints token contract.|


### onlyOwner

*Modifier to check if the caller is the owner.*


```solidity
modifier onlyOwner();
```

### setOwner


```solidity
function setOwner(address _newOwner) external onlyOwner;
```

### createAuction

Creates a new auction contract using create2.


```solidity
function createAuction(address auctionToken, uint256 biddingTime, uint256 totalTokens, bytes32 salt)
    external
    onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`auctionToken`|`address`||
|`biddingTime`|`uint256`|The duration of the auction in seconds.|
|`totalTokens`|`uint256`|The total number of tokens to be auctioned.|
|`salt`|`bytes32`|A unique salt for create2 to generate a deterministic address.|


## Events
### AuctionCreated

```solidity
event AuctionCreated(address indexed auctionAddress);
```

## Errors
### NotOwner

```solidity
error NotOwner();
```

### InvalidAddress

```solidity
error InvalidAddress();
```


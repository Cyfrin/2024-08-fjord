# FjordPoints
[Git Source](https://github.com/marigoldlabs/fjord-token/blob/e9ab36b35e88b3df615f78df9526e5509e82789f/src/FjordPoints.sol)

**Inherits:**
ERC20, ERC20Burnable, [IFjordPoints](/src/interfaces/IFjordPoints.sol/interface.IFjordPoints.md)

*ERC20 token to represent points distributed based on locked tokens in Staking contract.*


## State Variables
### owner
The owner of the contract


```solidity
address public owner;
```


### staking
The staking contract address


```solidity
address public staking;
```


### EPOCH_DURATION
Duration of each epoch for points distribution


```solidity
uint256 public constant EPOCH_DURATION = 1 weeks;
```


### lastDistribution
Timestamp of the last points distribution


```solidity
uint256 public lastDistribution;
```


### totalStaked
Total amount of tokens staked in the contract


```solidity
uint256 public totalStaked;
```


### pointsPerToken
Points distributed per token staked


```solidity
uint256 public pointsPerToken;
```


### totalPoints
Total points distributed by the contract


```solidity
uint256 public totalPoints;
```


### pointsPerEpoch
Points to be distributed per epoch


```solidity
uint256 public pointsPerEpoch;
```


### users
< Last recorded points per token for the user

Mapping of user addresses to their information


```solidity
mapping(address => UserInfo) public users;
```


### PRECISION_18
Constant


```solidity
uint256 public constant PRECISION_18 = 1e18;
```


## Functions
### constructor

*Sets the staking contract address and initializes the ERC20 token.*


```solidity
constructor() ERC20("BjordBoint", "BJB");
```

### onlyOwner

*Modifier to check if the caller is the owner of the contract.*


```solidity
modifier onlyOwner();
```

### onlyStaking

*Modifier to check if the caller is the staking contract.*


```solidity
modifier onlyStaking();
```

### updatePendingPoints

*Modifier to update pending points for a user.*


```solidity
modifier updatePendingPoints(address user);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user to update points for.|


### checkDistribution

*Modifier to check and distribute points.*


```solidity
modifier checkDistribution();
```

### setOwner


```solidity
function setOwner(address _newOwner) external onlyOwner;
```

### setStakingContract

Updates the staking contract.


```solidity
function setStakingContract(address _staking) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_staking`|`address`|The address of the staking contract.|


### setPointsPerEpoch

Updates the points distributed per epoch.


```solidity
function setPointsPerEpoch(uint256 _points) external onlyOwner checkDistribution;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_points`|`uint256`|The amount of points to be distributed per epoch.|


### onStaked

Records the amount of tokens staked by a user.


```solidity
function onStaked(address user, uint256 amount)
    external
    onlyStaking
    checkDistribution
    updatePendingPoints(user);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user staking tokens.|
|`amount`|`uint256`|The amount of tokens being staked.|


### onUnstaked

Records the amount of tokens unstaked by a user.


```solidity
function onUnstaked(address user, uint256 amount)
    external
    onlyStaking
    checkDistribution
    updatePendingPoints(user);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user unstaking tokens.|
|`amount`|`uint256`|The amount of tokens being unstaked.|


### distributePoints

Distributes points based on the locked amounts in the staking contract.


```solidity
function distributePoints() public;
```

### claimPoints

Allows users to claim their accumulated points.


```solidity
function claimPoints() external checkDistribution updatePendingPoints(msg.sender);
```

## Events
### Staked
Emitted when a user stakes tokens.


```solidity
event Staked(address indexed user, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user staking tokens.|
|`amount`|`uint256`|The amount of tokens staked.|

### Unstaked
Emitted when a user unstakes tokens.


```solidity
event Unstaked(address indexed user, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user unstaking tokens.|
|`amount`|`uint256`|The amount of tokens unstaked.|

### PointsDistributed
Emitted when points are distributed to stakers.


```solidity
event PointsDistributed(uint256 points, uint256 pointsPerToken);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`points`|`uint256`|The total number of points distributed.|
|`pointsPerToken`|`uint256`|The amount of points distributed per token staked.|

### PointsClaimed
Emitted when a user claims their accumulated points.


```solidity
event PointsClaimed(address indexed user, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the user claiming points.|
|`amount`|`uint256`|The amount of points claimed.|

## Errors
### InvalidAddress
Thrown when an invalid address (e.g., zero address) is provided to a function or during initialization.


```solidity
error InvalidAddress();
```

### DistributionNotAllowedYet
Thrown when a distribution attempt is made before the allowed time (e.g., before the epoch duration has passed).


```solidity
error DistributionNotAllowedYet();
```

### NotAuthorized
Thrown when an unauthorized caller attempts to execute a restricted function.


```solidity
error NotAuthorized();
```

### UnstakingAmountExceedsStakedAmount
Thrown when a user attempts to unstake an amount that exceeds their currently staked balance.


```solidity
error UnstakingAmountExceedsStakedAmount();
```

### TotalStakedAmountZero
Thrown when an operation requires a non-zero total staked amount, but the total staked amount is zero.


```solidity
error TotalStakedAmountZero();
```

### CallerDisallowed
Thrown when a disallowed caller attempts to execute a function that is restricted to specific addresses.


```solidity
error CallerDisallowed();
```

## Structs
### UserInfo
*Structure to hold user-specific information*


```solidity
struct UserInfo {
    uint256 stakedAmount;
    uint256 pendingPoints;
    uint256 lastPointsPerToken;
}
```


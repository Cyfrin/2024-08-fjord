# FjordStaking
[Git Source](https://github.com/marigoldlabs/fjord-token/blob/e9ab36b35e88b3df615f78df9526e5509e82789f/src/FjordStaking.sol)

**Inherits:**
ISablierV2LockupRecipient


## State Variables
### owner
-----------------------------------------------------------------------
Mutable Storage
-----------------------------------------------------------------------

The owner of the staking contract.


```solidity
address public owner;
```


### sablier
The address of the sablier vesting contrat.


```solidity
ISablierV2Lockup public sablier;
```


### points
The address of the fjord points contract.


```solidity
IFjordPoints public points;
```


### deposits
Deposit receipts for staking, user => epoch => deposit receipt


```solidity
mapping(address user => mapping(uint16 epoch => DepositReceipt)) public deposits;
```


### claimReceipts
Claim receipt receipts for reawrds, user => epoch => claim receipt


```solidity
mapping(address user => ClaimReceipt) public claimReceipts;
```


### _activeDeposits
Active deposits by the user, user => set of epoch


```solidity
mapping(address user => EnumerableSet.UintSet epochIds) private _activeDeposits;
```


### _streamIDs
StreamIDs of the vested FJO staked, user => streamID => NFTData


```solidity
mapping(address user => mapping(uint256 streamID => NFTData)) private _streamIDs;
```


### _streamIDOwners
Owners of staked streams


```solidity
mapping(uint256 streamID => address user) private _streamIDOwners;
```


### userData
User stakes and rewards data


```solidity
mapping(address user => UserData) public userData;
```


### rewardPerToken
Rewards distributed accumulated up to the epoch
rewardPerToken in each epoch will be updated one and only one, epoch => rewardPerToken


```solidity
mapping(uint16 epoch => uint256) public rewardPerToken;
```


### totalStaked
Total staked


```solidity
uint256 public totalStaked;
```


### totalVestedStaked
Total vested staked


```solidity
uint256 public totalVestedStaked;
```


### newStaked
New staked


```solidity
uint256 public newStaked;
```


### newVestedStaked
New vested staked


```solidity
uint256 public newVestedStaked;
```


### totalRewards
Total rerwards


```solidity
uint256 public totalRewards;
```


### currentEpoch
Current epoch cycle number.


```solidity
uint16 public currentEpoch;
```


### lastEpochRewarded
Last epoch when rewards were distributed.


```solidity
uint16 public lastEpochRewarded;
```


### authorizedSablierSenders
Mapping of authorized Sablier stream senders.


```solidity
mapping(address authorizedSablierSender => bool) public authorizedSablierSenders;
```


### epochDuration
-----------------------------------------------------------------------
Immutable Storage
-----------------------------------------------------------------------

One epoch time in seconds.


```solidity
uint256 public constant epochDuration = 86_400 * 7;
```


### lockCycle
Lock duration in epoch cycles.


```solidity
uint8 public constant lockCycle = 6;
```


### PRECISION_18
Constant


```solidity
uint256 public constant PRECISION_18 = 1e18;
```


### claimCycle
Claim cooldown duration in epoch cycles.


```solidity
uint8 public constant claimCycle = 3;
```


### fjordToken
Address of FJORD token.


```solidity
ERC20 public immutable fjordToken;
```


### startTime
Start time of the staking contract.


```solidity
uint256 public immutable startTime;
```


### rewardAdmin
Reward admin.


```solidity
address public rewardAdmin;
```


## Functions
### constructor

CONSTRUCTOR & INITIALIZATION

Initializes the contract with starting variables


```solidity
constructor(
    address _fjordToken,
    address _rewardAdmin,
    address _sablier,
    address _authorizedSablierSender,
    address _fjordPoints
);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_fjordToken`|`address`|is the FJORD token contract|
|`_rewardAdmin`|`address`|is the Fee distributor contract|
|`_sablier`|`address`||
|`_authorizedSablierSender`|`address`||
|`_fjordPoints`|`address`||


### onlyOwner


```solidity
modifier onlyOwner();
```

### onlyRewardAdmin


```solidity
modifier onlyRewardAdmin();
```

### checkEpochRollover


```solidity
modifier checkEpochRollover();
```

### redeemPendingRewards


```solidity
modifier redeemPendingRewards();
```

### onlySablier


```solidity
modifier onlySablier();
```

### getEpoch


```solidity
function getEpoch(uint256 _timestamp) public view returns (uint16);
```

### getActiveDeposits


```solidity
function getActiveDeposits(address _user) public view returns (uint256[] memory);
```

### getStreamData


```solidity
function getStreamData(address _user, uint256 _streamID) public view returns (NFTData memory);
```

### getStreamOwner


```solidity
function getStreamOwner(uint256 _streamID) public view returns (address);
```

### setOwner


```solidity
function setOwner(address _newOwner) external onlyOwner;
```

### setRewardAdmin


```solidity
function setRewardAdmin(address _rewardAdmin) external onlyOwner;
```

### addAuthorizedSablierSender


```solidity
function addAuthorizedSablierSender(address _address) external onlyOwner;
```

### removeAuthorizedSablierSender


```solidity
function removeAuthorizedSablierSender(address _address) external onlyOwner;
```

### stake

Stake FJORD tokens into the contract.

*This function allows users to stake a certain number of FJORD tokens.*


```solidity
function stake(uint256 _amount) external checkEpochRollover redeemPendingRewards;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount of tokens user wants to stake.|


### stakeVested

Stake vested FJORD tokens into the contract.

*This function allows users to stake a certain their NFT from
sablier that contains FJORD tokens.*


```solidity
function stakeVested(uint256 _streamID) external checkEpochRollover redeemPendingRewards;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_streamID`|`uint256`|The streamID of the vested NFT.|


### unstake

Unstake FJORD tokens from the contract.

*This function allows users to unstake a certain number of FJORD tokens,
while also claiming all the pending rewards. If _isEarly is true then the
user will be able to bypass rewards cooldown of 3 epochs and claim early,
but will incur early claim penalty.*


```solidity
function unstake(uint16 _epoch, uint256 _amount)
    external
    checkEpochRollover
    redeemPendingRewards
    returns (uint256 total);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_epoch`|`uint16`|The epoch cycle from which user wants to unstake.|
|`_amount`|`uint256`|The amount of tokens user wants to unstake.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`total`|`uint256`|The total amount sent to the user.|


### unstakeVested

Unstake vested FJORD tokens from the contract.

*This function allows users to unstake vested FJORD tokens,
while also claiming all the pending rewards. If _isClaimEarly is true then the
user will be able to bypass rewards cooldown of 3 epochs and claim early,
but will incur early claim penalty.*


```solidity
function unstakeVested(uint256 _streamID) external checkEpochRollover redeemPendingRewards;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_streamID`|`uint256`|The sablier streamID that the user staked.|


### _unstakeVested

Partial or fully unstake vested .


```solidity
function _unstakeVested(address streamOwner, uint256 _streamID, uint256 amount) internal;
```

### unstakeAll

Unstake from all epochs.

*This function allows users to unstake from all the epochs at once,
while also claiming all the pending rewards.*


```solidity
function unstakeAll()
    external
    checkEpochRollover
    redeemPendingRewards
    returns (uint256 totalStakedAmount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalStakedAmount`|`uint256`|The total amount that has been unstaked.|


### claimReward

Claim reward from specific epoch.

*This function allows users to claim rewards from an epochs,
if the user chooses to bypass the reward cooldown of 3 epochs,
then reward penalty will be levied.*


```solidity
function claimReward(bool _isClaimEarly)
    external
    checkEpochRollover
    redeemPendingRewards
    returns (uint256 rewardAmount, uint256 penaltyAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_isClaimEarly`|`bool`|Whether user wants to claim early and incur penalty.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardAmount`|`uint256`|The reward amount that has been distributed.|
|`penaltyAmount`|`uint256`|The penalty incurred by the user for early claim.|


### completeClaimRequest

Comaplete claim receipt from specific epoch.

*This function allows users to complete claim receipt from an epoch*


```solidity
function completeClaimRequest()
    external
    checkEpochRollover
    redeemPendingRewards
    returns (uint256 rewardAmount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardAmount`|`uint256`|The reward amount that has been distributed.|


### _checkEpochRollover

Check and update epoch rollover.

*rollover to latest epoch, gap epoches will be filled with previous epoch reward per token*


```solidity
function _checkEpochRollover() internal;
```

### _redeem

accumulate unclaimed rewards for the user from last non-zero unredeemed epoch
This function should run before every tx user does, so state is correctly maintained everytime
Last unredeemed epoch will be the last epoch user staked


```solidity
function _redeem(address sender) internal;
```

### addReward

addReward should be called by master chef
must be only call if it's can trigger update next epoch so the total staked won't increase anymore
must be the action to trigger update epoch and the last action of the epoch


```solidity
function addReward(uint256 _amount) external onlyRewardAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount of tokens to be added as rewards.|


### calculateReward

Calculate reward for a given amount from _fromEpoch to _toEpoch


```solidity
function calculateReward(uint256 _amount, uint16 _fromEpoch, uint16 _toEpoch)
    internal
    view
    returns (uint256 rewardAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amount`|`uint256`|The amount of tokens staked.|
|`_fromEpoch`|`uint16`|The epoch from which reward calculation starts.|
|`_toEpoch`|`uint16`|The epoch till which reward calculation is done.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardAmount`|`uint256`|The reward amount that has been distributed.|


### onStreamWithdrawn

Responds to withdrawals triggered by either the stream's sender or an approved third party.

if onStreamWithdrawn is implemented inproperly, the execution flow still continues.

*Notes:
- This function may revert, but the Sablier contract will ignore the revert.*


```solidity
function onStreamWithdrawn(uint256, address, address, uint128) external override onlySablier;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`||
|`<none>`|`address`||
|`<none>`|`address`||
|`<none>`|`uint128`||


### onStreamRenounced

Responds to renouncements.

Renouncing a stream means that the sender of the stream will no longer be able to cancel it.
This is useful if the sender wants to give up control of the stream.

onStreamRenounced never be called with non-cancelable stream
and does nothing effect on the staking contract

*Notes:
- This function may revert, but the Sablier contract will ignore the revert.*


```solidity
function onStreamRenounced(uint256) external override onlySablier;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`||


### onStreamCanceled

onStreamCanceled never be called with non-cancelable stream

Responds to sender-triggered cancellations.

*Notes:
- This function may revert, but the Sablier contract will ignore the revert.*


```solidity
function onStreamCanceled(uint256 streamId, address sender, uint128 senderAmount, uint128)
    external
    override
    onlySablier
    checkEpochRollover;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`streamId`|`uint256`|The id of the canceled stream.|
|`sender`|`address`|The stream's sender, who canceled the stream.|
|`senderAmount`|`uint128`|The amount of assets refunded to the stream's sender, denoted in units of the asset's decimals.|
|`<none>`|`uint128`||


## Events
### Staked
-----------------------------------------------------------------------
Dependencies
-----------------------------------------------------------------------
-----------------------------------------------------------------------
Events
-----------------------------------------------------------------------

*Emitted when tokens are staked in the contract.*


```solidity
event Staked(address indexed user, uint16 indexed epoch, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the stake.|
|`epoch`|`uint16`|The current epoch cycle.|
|`amount`|`uint256`|The amount of tokens received in the stake.|

### VestedStaked
*Emitted when vested FJORD tokens are staked in the contract.*


```solidity
event VestedStaked(
    address indexed user, uint16 indexed epoch, uint256 indexed streamID, uint256 amount
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the stake.|
|`epoch`|`uint16`|The current epoch cycle.|
|`streamID`|`uint256`|The stream id of the NFT.|
|`amount`|`uint256`|The amount of tokens received in the stake.|

### RewardAdded
*Emitted when rewards are added in the contract.*


```solidity
event RewardAdded(uint16 indexed epoch, address rewardAdmin, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`epoch`|`uint16`|The current epoch cycle.|
|`rewardAdmin`|`address`||
|`amount`|`uint256`|The amount of tokens added as rewards.|

### RewardClaimed
*Emitted when rewards are claimed by the user.*


```solidity
event RewardClaimed(address indexed user, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the claim.|
|`amount`|`uint256`|The amount of rewards given.|

### EarlyRewardClaimed
*Emitted when rewards are claimed by the user before cooldown.*


```solidity
event EarlyRewardClaimed(address indexed user, uint256 rewardAmount, uint256 penaltyAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the claim.|
|`rewardAmount`|`uint256`|The amount of rewards given.|
|`penaltyAmount`|`uint256`|The amount of tokens deducted as penalty.|

### ClaimedAll
*Emitted when user claims rewards from all epoch cycles.*


```solidity
event ClaimedAll(address indexed user, uint256 totalRewardAmount, uint256 totalPenaltyAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the claim.|
|`totalRewardAmount`|`uint256`|The total reward amount given.|
|`totalPenaltyAmount`|`uint256`|The total amount penalised for early claim.|

### Unstaked
*Emitted when user unstakes the deposit.*


```solidity
event Unstaked(address indexed user, uint16 indexed epoch, uint256 stakedAmount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the unstake.|
|`epoch`|`uint16`|The epoch cycle for which unstake is initiated.|
|`stakedAmount`|`uint256`|The staked amount for the user.|

### VestedUnstaked
*Emitted when user unstakes the vested FJO.*


```solidity
event VestedUnstaked(
    address indexed user, uint16 indexed epoch, uint256 stakedAmount, uint256 streamID
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the unstake.|
|`epoch`|`uint16`|The epoch cycle for which unstake is initiated.|
|`stakedAmount`|`uint256`|The staked amount for the user.|
|`streamID`|`uint256`|The stream id of the NFT.|

### UnstakedAll
*Emitted when user unstakes the deposit from all epoch cycles.*


```solidity
event UnstakedAll(
    address indexed user,
    uint256 totalStakedAmount,
    uint256[] activeDepositsBefore,
    uint256[] activeDepositsAfter
);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the unstake.|
|`totalStakedAmount`|`uint256`|The total staked amount for the user.|
|`activeDepositsBefore`|`uint256[]`|The epochs with active deposit in which user staked before unstake.|
|`activeDepositsAfter`|`uint256[]`|The epochs with active deposit in which user staked after unstake.|

### ClaimReceiptCreated
*Emitted when user create a claim receipt.*


```solidity
event ClaimReceiptCreated(address indexed user, uint16 requestEpoch);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The address of the caller initiating the claim receipt.|
|`requestEpoch`|`uint16`|The epoch of claim receipt.|

### RewardPerTokenChanged
*Emitted when user claims reward from the claim receipt.*


```solidity
event RewardPerTokenChanged(uint16 epoch, uint256 rewardPerToken);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`epoch`|`uint16`|The epoch cycle for which reward is changed.|
|`rewardPerToken`|`uint256`|The amount of reward for given epoch.|

### SablierWithdrawn
*Emitted when sablier withdrawn hook is invoked.*


```solidity
event SablierWithdrawn(address indexed user, uint256 streamID, address caller, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The owner that stake stream id.|
|`streamID`|`uint256`|The stream id of the NFT.|
|`caller`|`address`|The stream sender that withdrawn the stream.|
|`amount`|`uint256`|The amount of tokens withdrawn.|

### SablierCanceled
*Emitted when sablier withdrawn hook is invoked.*


```solidity
event SablierCanceled(address indexed user, uint256 streamID, address caller, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`user`|`address`|The owner that stake stream id.|
|`streamID`|`uint256`|The stream id of the NFT.|
|`caller`|`address`|The stream sender that withdrawn the stream.|
|`amount`|`uint256`|The amount of tokens unstake.|

## Errors
### CallerDisallowed
-----------------------------------------------------------------------
Errors
-----------------------------------------------------------------------

*Error thrown when an address is not allowed to call a function.*


```solidity
error CallerDisallowed();
```

### InvalidAmount
*Error thrown when a given amount is not in valid range.*


```solidity
error InvalidAmount();
```

### UnstakeEarly
*Error thrown when unstake a deposit too early.*


```solidity
error UnstakeEarly();
```

### ClaimTooEarly
*Error thrown when claim reward too early.*


```solidity
error ClaimTooEarly();
```

### DepositNotFound
*Error thrown when a deposit is not found.*


```solidity
error DepositNotFound();
```

### ClaimReceiptNotFound
*Error thrown when a claim receipt is not found.*


```solidity
error ClaimReceiptNotFound();
```

### NoActiveDeposit
*Error thrown when a user have no active deposit.*


```solidity
error NoActiveDeposit();
```

### UnstakeMoreThanDeposit
*Error thrown when try to unstake more amount than the given deposit available.*


```solidity
error UnstakeMoreThanDeposit();
```

### NotAStream
*Error thrown when user tries to stake an NFT that doesn't exists.*


```solidity
error NotAStream();
```

### StreamNotSupported
*Error thrown when user tries to stake an NFT that is not supported.*


```solidity
error StreamNotSupported();
```

### NotAWarmStream
*Error thrown when user tries to stake an NFT a cold stream.*


```solidity
error NotAWarmStream();
```

### InvalidAsset
*Error thrown sablier vesting NFT is not of FJO token.*


```solidity
error InvalidAsset();
```

### NothingToClaim
*Error thrown when there is nothing to claim.*


```solidity
error NothingToClaim();
```

### StreamOwnerNotFound
*Error thrown when stream owner not found.*


```solidity
error StreamOwnerNotFound();
```

### InvalidZeroAddress
*Error thrown when address is zero.*


```solidity
error InvalidZeroAddress();
```

### CompleteRequestTooEarly
*Error thrown when complete claim request too early.*


```solidity
error CompleteRequestTooEarly();
```


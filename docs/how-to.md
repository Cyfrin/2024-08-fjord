# Index
- [Stake FJO](#how-to-stake-fjo)
- [Stake vested FJO](#how-to-stake-vested-fjo)
- [Add reward](#how-to-add-reward)
- [claim rewads](#how-to-claim-rewards)
- [Create an auction](#how-to-create-an-auction)

> All linked script will work with copied `.env.example` into `.env` filled with keys in conjuction with `foundry.toml`

# How to stake FJO
See functional Stake bash script with cast [here](../script/sh/createStakes.sh)

## Approve FJO token to be used by FjordStaking
```sh
cast send 0xFjordToken "approve(address,uint256)" 0xFjordStaking 100000000000000000000000
```

## Stake FJO token into FjordStaking
```sh
cast send 0xfjordStaking "stake(uint256)" 1000000000000000000000
```

# How to stake vested FJO
Only vested token on Sablier by the `AUTHORIZED_SENDER` can be staked on Fjord.

## Approve FJO token to be used by Sablier contract
```sh
cast send 0xFjordToken "approve(address,uint256)" 0xSablierV2LockupLinear 100000000000000000000000
```

## Vesting some FJO token into Sablier
```sh
cast send 0xSablierV2LockupLinear "createWithDurations((address,address,uint128,address,bool,bool,(uint40,uint40),(address,uint256)))" \
"(${SENDER},${RECIPIENT},${TOTAL_AMOUNT},${ASSET},${CANCELABLE},${TRANSFERABLE},("${VESTING_START}","${VESTING_END}"),("${BROKER_ADR}","${PERCENT}"))"
```

## Approve Sablier TokenID to be used by fjordStaking
```sh
cast send 0xSablierV2LockupLinear "approve(address,uint256)" 0xfjordStaking ${STREAM_ID}
```

## Stake the vested FJO
```sh
cast send 0xfjordStaking "stakeVested(uint256)" ${STREAM_ID}
```

# How to add reward
See functional reward bash script with cast [here](../script/sh/createRewards.sh)

## Anyone can transfer some FJO into 0xfjordStaking
```sh
cast send 0xFjordToken "transfer(address,uint256)" 0xfjordStaking 42
```

## Approve FJO to be used by 0xfjordStaking
```sh
cast send 0xFjordToken "approve(address,uint256)" 0xfjordStaking 123
```

## To better keep track of officials added Rewards we got that helper function that only rewardAdmin can call
```sh
cast send 0xfjordStaking "addReward(uint256)" 123
```

# How to claim rewards
See functional reward bash script with cast [here](../script/sh/createClaims.sh)

## Verify that you got staked position(s)
```sh
cast call 0xfjordStaking "getActiveDeposits(address)(uint256[])"
```

## Verify all your staked position(s) metadata
```sh
cast call 0xfjordStaking "userData(address)(uint256,uint256,uint16,uint16)" 0xuserAddress
```

## Verify your claimed intention(s)
```sh
cast call 0xfjordStaking "claimReceipts(address)(uint16,uint256)" 0xuserAddress
```

## Create a new claim rewards claim
You must not have a claimReceipts ongoing.
Param  claimEarly `true` to instant claim and get penalized or `false` to wait 3 epoch.
```sh
cast send 0xfjordStaking "claimReward(bool)" false
```

## Complete all claimed intentions
You must have a clain receipt and the epoch should match
```sh
cast send 0xfjordStaking "completeClaimRequest()"
```

## Claim points - admin must trigger the distributePoints
When and conditions for admin to call it
```sh
cast send 0xFjordPoint "distributePoints()"
```

## Verify your pending points
```sh
cast call 0xFjordPoint "users(address)(uint256,uint256,uint256)" 0xuserAddress
```

## Claim points - User to claim pending points
```sh
cast send 0xFjordPoint "claimPoints()"
```

# How to create an auction
See functional reward bash script with cast [here](../script/sh/createAuction.sh)

## Approve FJO to be used by 0xfjordStaking
```sh
cast send 0xFjordToken "approve(address,uint256)" 0xAuctionFactory 123456
```

## Create the Auction 
Only able to call by the owner ok 0xAuctionFactory
```sh
cast send 0xAuctionFactory "createAuction(address,uint256,uint256,bytes32)" \
    ${PROJECT_TOKEN} ${BIDDING_TIME} ${PROJECT_TOKEN_AMOUT} ${HASH}
```

## Check if auction is start and not close

## Approve FJO token to be used by FjordStaking
```sh
cast send 0xFjordPoint "approve(address,uint256)" 0xNewAuction 100000000000000000000000
```

## bid on auction
```sh
cast send 0xNewAuction "bid(uint256)" 500000000000000000000
```

```sh
cast send 0xNewAuction "unbid(uint256)" 100000000000000000000
```

## New Auction is close

## User get auction token
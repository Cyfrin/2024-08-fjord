# FJORD Token & Staking

## Project Overview

Ford token (FJO) holder are able to stake their `FJO` to get rewards. 
This staking position will be locked and from time to time users can claim the collected rewards.

### 1. Function Requirements

#### 1.1 Roles
There are is a single role that exists per contract:
##### `FjordStaking`
The owner of the staking contract.
##### `FjordToken`
For Fjord token contract there is no `owner` but only the deployer can `transfer` the initial balance of `FJO` erc20.


#### 1.2 Features
Fjord Staking offers the following features:
- Staked tokens will be locked for 6 weeks(6 epochs) and can be unstaked after that, but they will continue to accrue rewards.
- The accrued rewards can be claimed without unstaking the initial amount. When the claim request is done, then the user can either wait 21 days and claim full rewards or redeem before 21 days(3 epochs) and get 50% rewards.
- Lock and claim mechanism will happen during epochs. One epoch is 7 days and all the deposit and claim requests in the same epoch will be treated as being the same.
- The deposit amount will be locked for 6 epochs, at the time of deposit the share that needs to be given and the pricePerShare(PPS) of that epoch will be recorded.
- Every epoch the PPS value will be recorded when the rewards will be distributed, this will make sure that epoch is incremented properly and with valid rewards.
- When the user comes for claim request for a particular DepositLock there can be 2 scenarios
  - They want immediate redeem, then rewards will be calculated based on current epoch and 50% will be returned to user and remaining should be adjusted in the PPS.
  - They can wait for 3 epochs and a claim request will be generated and after these 3 epochs they can come and redeem rewards based on the current epoch.


#### 1.3 Use Case
- Users holding FJO token can stake the tokens and earn APY.
- Users holding vested FJO token(Sablier NFT) can also stake.
- Rewards will be distributed on a weekly basis and can be claimed by the stakers anytime.
- Stakers can also unstake at any point barring the initial locking period.


### 2. Technical Requirements
FjordStaking is developed in Solidity 0.8.21, using Foundry for our development environment.
Additionally, FjordStaking utilizes `Solmate`, `prb-math`, `Sablier V2-Core`, and `openzeppelin-contract`. All informations about these libraries can be found within the lib directory in the Fjord-token repository.

Our project is structured as follows:

```sh
  .
├──  .book.toml
├──  .env.example
├──  .gas-snapshot
├──  .gitattributes
├──  .github
│   └──  workflows
│       └──  ci.yml
├──  .gitignore
├──  .gitmodules
├──  codecov.yml
├──  doc
│   ├──  forge-doc
│   └──  product_requirements.md
├──  foundry.toml
├──  lib
│   ├──  forge-std
│   ├──  openzeppelin-contracts
│   ├──  prb-math
│   ├──  solmate
│   └──  v2-core
├──  LICENSE
├──  Makefile
├──  README.md
├──  remappings.txt
├──  script
│   ├──  forge
│   │   ├──  DeployStaking.s.sol
│   │   └──  DeployToken.s.sol
│   └──  sh
│       ├──  coverage.sh
│       ├──  deploy-staking.sh
│       ├──  deploy-token.sh
│       └──  forge-doc-gen.sh
├── 󱧼 src
│   ├──  FjordStaking.sol
│   ├──  FjordToken.sol
│   └──  interfaces
│       └──  IStaking.sol
└──  test
    ├──  FjordStakingBase.t.sol
    ├──  integration
    │   ├──  bothClaim.t.sol
    │   ├──  bothStake.t.sol
    │   ├──  bothUnstake.t.sol
    │   ├──  stakeReward.t.sol
    │   ├──  stakeUnstake.t.sol
    │   └──  vestStake.t.sol
    ├──  invariant
    │   ├──  fuzzInstantUnstake.t.sol
    │   └──  fuzzStake.t.sol
    ├──  security
    │   ├──  SecurityCheckList.md
    │   └──  TestHedgyFlashLoan.t.sol
    └──  unit
        ├──  addReward.t.sol
        ├──  claimReward.t.sol
        ├──  completeReceipt.t.sol
        ├──  epoch.t.sol
        ├──  setRewardAdmin.t.sol
        ├──  stake.t.sol
        ├──  stakeVested.t.sol
        ├──  unstake.t.sol
        ├──  unstakeAll.t.sol
        ├──  unstakeInstant.t.sol
        └──  unstakeVested.t.sol
```

Begin with the [README.md](/README.md) to find all information required to properly configure the environment and deploy the contracts.

Project configuration can be found in the `foundry.toml`, `env.example`, and `remappings.txt` files which are utilized by Forge in order to test, deploy, and configure the development environment.

Inside [/script](../script/) you can find the [/forge](../script/forge/) deploy scripts and the [/sh](../script/sh/) that contain all bash scripts that are used to ease the use of `Makefile`.

In [/src](../src/) directory, you’ll find 
- FjordToken.sol
`FjordToken` implements the ERC20 for Fjord(FJO) token with `solmate/tokens/ERC20.sol`.
- FjordStaking.sol
`FjordStaking` implements  `solmate/tokens/ERC20.sol`, `@openzeppelin/contracts/token/ERC20/IERC20.sol`, `@openzeppelin/contracts/utils/structs/EnumerableSet.sol` and `solmate/utils/SafeTransferLib.sol`. Additionally, it implements Sablier’s ISablierV2LockupLinear, DataTypes, Math, and Tokens libraries, which are used to set up Sablier vesting streams. 

In [/test](../test/) directory, `FjordStakingBase.t.sol` acts as the base testing file that are utilized further within the [/integration](../test/integration/), [/invariant](../test/invariant/), [/security](../test/security/) and [/unit](../test/unit/) subdirectories.

In [/deployments]() folder archive versions with smart contract addresses, abis organised by chainID.

Lastly, a whole host of documentation can be found in the [/docs](../doc/) directory, including forge-automated documentation.


#### 2.1 Architecture Overview
Links to our architecture and interaction diagrams can be found below:
- TODO lucid chart here
- TODO excalidraw here


####  2.2 Contract Information
- TODO describe function and flow here
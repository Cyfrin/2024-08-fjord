# Fjord Token Staking

[//]: # (contest-details-open)

### Prize Pool TO BE FILLED OUT BY CYFRIN

- Total Pool - 
- H/M -  
- Low - 
- Community Judging - 

- Starts: 
- Ends: 

- nSLOC: 
- Complexity Score:

## About the Project

This repository is the Staking contract for the Fjord ecosystem. Users who gets some ERC20 emitted by Fjord Foundry can stake them to get rewards.

[Documentation](https://help.fjordfoundry.com/fjord-foundry-docs)
[Forge Documentation](/docs/)
[Previous audits](/docs/audit/)
[Website](https://www.fjordfoundry.com/)
[Twitter](https://x.com/FjordFoundry)
[GitHub](https://github.com/marigoldlabs)

## Actors

- __AuthorizedSender__: Address of the owner whose cancellable Sablier streams will be accepted.
- __Buyer__: User who aquire some ERC20 FJO token.
- __Vested Buyer__: User who get some ERC721 vested FJO on Sablier created by Fjord.
- __FJO-Staker__: Buyer who staked his FJO token on the Fjord Staking contract.
- __vFJO-Staker__: Vested Buyer who staked his vested FJO on Sablier created by Fjord, on the Fjord Staking contract.
- __Penalised Staker__: a Staker that claim rewards before 3 epochs or 21 days.
- __Rewarded Staker__: Any kind of Stakers who got rewarded with Fjord's reward or with ERC20 BJB.
- __Auction Creator__: Only the owner of the AuctionFactory contract can create an auction and offer a valid project token earn by a "Fjord LBP event" as an auctionToken to bid on.
- __Bidder__: Any Rewarded Staker that bid his BJB token inside a Fjord's auctions contract.

[//]: # (contest-details-close)

[//]: # (scope-open)

## Scope (contracts)

All Contracts in `src` are in scope.

```js
src/
├── FjordAuction.sol
├── FjordAuctionFactory.sol
├── FjordPoints.sol
├── FjordStaking.sol
├── FjordToken.sol
└── interfaces
    └── IFjordPoints.sol
```

## Compatibilities

> whiteliste address
-  On the staking contract the owner can define new `addAuthorizedSablierSender` or `removeAuthorizedSablierSender` for the contract to be able to access new vested FJO from Sablier on the Fjord Staking contract.
- On the staking contract the owner can define new `setRewardAdmin` to allow that new address to be able to call `addReward`.

__Solc:__ version: =0.8.21  
__Blockchains:__ Ethereum  
__Tokens:__
- Ford Token (FJO) [FJO contract](/src/FjordToken.sol)
- FJO vested on Sablier <= v1.1.2 Lockup Linear by Fjord (vFJO)
- Bjord Boint (BJB) [BJB contract](/src/FjordPoints.sol)
- ERC20 that did a successfull raise on Fjord Foundry LBP. (aka no exotic ERC20 with hooks)


[//]: # (scope-close)

[//]: # (getting-started-open)

## Setup

Env:
```bash
SABLIERV2_LOCKUPLINEAR= # address of Sablier V2 Lockup Linear <= v1.1.2
FJO_ADDRESS= # address of FJO Token contract
AUTHORIZED_SENDER= # EOA or SAFE wallet address
```

Build:
```bash
forge init

forge install transmissions11/solmate@v7 --no-commit

forge install OpenZeppelin/openzeppelin-contracts@release-v4.5 --no-commit

forge install sablier-labs/v2-core@v1.1.2 --no-commit

forge install PaulRBerg/prb-math --no-commit
```

Remappings:
```
@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
@prb/math/=lib/prb-math/
@sablier/v2-core/=lib/v2-core/
ds-test/=lib/forge-std/lib/ds-test/src/
erc4626-tests/=lib/openzeppelin-contracts/lib/erc4626-tests/
forge-std/=lib/forge-std/src/
openzeppelin-contracts/=lib/openzeppelin-contracts/
prb-math/=lib/prb-math/src/
solmate/=lib/solmate/src/
v2-core/=lib/v2-core/src/
lib/forge-std:ds-test/=lib/forge-std/lib/ds-test/src/
lib/openzeppelin-contracts:@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
lib/openzeppelin-contracts:ds-test/=lib/openzeppelin-contracts/lib/forge-std/lib/ds-test/src/
lib/openzeppelin-contracts:erc4626-tests/=lib/openzeppelin-contracts/lib/erc4626-tests/
lib/openzeppelin-contracts:forge-std/=lib/openzeppelin-contracts/lib/forge-std/src/
lib/solmate:ds-test/=lib/solmate/lib/ds-test/src/
lib/v2-core:@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/
```

Clean:
```bash
rm -rf test/Counter.t.sol
```

Foundry.toml
```toml
solc_version = "0.8.21"
ffi = false
optimizer-runs = 10000
via_ir = true
```

```bash
forge build
```

Tests:
```bash
Forge test
```

[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues

TODO

```
Please clearly detail **all** currently recognized issues or vulnerabilities within the scope submitted. Please be thorough and precise, following the end of the 48-hour Kick-Off period, these Known Issues will be immutable for the duration of the contest.

Example:


Known Issues:
- Addresses other than the zero address (for example 0xdead) could prevent disputes from being resolved -
Before the buyer deploys a new Escrow, the buyer and seller should  agree to the terms for the Escrow. If the
buyer accidentally or maliciously deploys an Escrow with incorrect arbiter details, then the seller could refuse
to provide their services. Given that the buyer is the actor deploying the new Escrow and locking the funds, it's
in their best interest to deploy this correctly.

- Large arbiter fee results in little/no seller payment - In this scenario, the seller can decide to not perform
the audit. If this is the case, the only way the buyer can receive any of their funds back is by initiating the dispute
process, in which the buyer loses a large portion of their deposited funds to the arbiter. Therefore, the buyer is
disincentivized to deploy a new Escrow in such a way.

- Tokens with callbacks allow malicious sellers to DOS dispute resolutions - Each supported token will be vetted
to be supported. ERC777 should be discouraged.

- Buyer never calls confirmReceipt - The terms of the Escrow are agreed upon by the buyer and seller before deploying
it. The onus is on the seller to perform due diligence on the buyer and their off-chain identity/reputation before deciding
to supply the buyer with their services.

- Salt input when creating an Escrow can be front-run

- arbiter is a trusted role

- User error such as buyer calling confirmReceipt too soon

- Non-tokenAddress funds locked
```

[//]: # (known-issues-close)

# Fjord Token Staking

### Prize Pool

- Total Pool - $20,000
- H/M -  $16,000
- Low - $2,500
- Community Judging - $1,500

- Ends: August 27, 2024 Noon UTC

- nSLOC: 662

[//]: # (contest-details-open)

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

Build:
```bash
git clone https://github.com/Cyfrin/2024-08-fjord
cp -iv .env.example .env
make init
```

Env:
Fill the API keys or RPC for you provider.

Test:
```bash
make test
```

Deploy:
You can deploy the FJO token and the staking with make, it accept chain(c) argument.
it must match from your `foundry.toml` the tables in `[rpc_endpoint]` and `[etherscan]`.

all deploy script maid with make will use the inputs inside `deployments/safe.json` and produice a json to recap your metadata deployment and ABIs.


To deploy FJO token you can use make or deploy manually the `script/forge/DeployToken.s.sol`
```bash
make deploy-token c=sepolia
```

To deploy Staking you need to reference inside `deployments/safe.json` or as emvironement variables if you deploy manually the `script/forge/DeployStaking.s.sol` the following addresses:
```
FJO_ADDRESS - Address of Fjord Token
SABLIERV2_LOCKUPLINEAR - Address of Sablier Lockup Linear <= v1.1.2 smart contract
AUTHORIZED_SENDER - Address of the owner whose cancellable Sablier streams will be accepted
```

```bash
make deploy-staking c=sepolia
```

[//]: # (getting-started-close)

[//]: # (known-issues-open)

## Known Issues

Exotic ERC20 Tokens
If an exotic ERC20 token is selected as the Auction token during an auction, it may trigger unexpected behavior due to the unique mechanics or additional features embedded within the token.

Additional Fees: Some ERC20 tokens include mechanisms like transfer fees, burn rates, or automatic redistribution to holders. When such a token is used in the auction, these fees could be inadvertently passed on to users, resulting in higher-than-expected costs.

Price Impact: The presence of such fees or mechanisms can also affect the overall pricing dynamics. This could result in users either overpaying or receiving less value than anticipated, depending on the token's specific behavior.

Compatibility Issues: Some exotic ERC20 tokens might not fully comply with the standard ERC20 interface or could include functions that behave differently than expected in certain situations. This could lead to unintended interactions or failures within the auction contract, impacting the overall integrity of the auction process.

Common ERC20 Hooks: Many ERC20 tokens incorporate hooks like beforeTransfer, afterTransfer, beforeApproval, or afterApproval that allow custom logic to be executed before or after token transfers and approvals. These hooks can introduce unexpected side effects in an auction setting. 

Recommendation
It is recommended to use well-established and standard-compliant ERC20 tokens to avoid these issues. If an exotic token with hooks or other custom features must be used, thorough testing should be conducted to understand its behavior and the potential impact on the auction process. Some Hooks should be disable if possible during the Auction.

**Additional Known Issues as detected by LightChaser can be found [here](https://github.com/Cyfrin/2024-08-fjord/issues/1)**

[//]: # (known-issues-close)

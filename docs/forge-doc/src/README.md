# Fjord Token Staking [![Github Actions][gha-badge]][gha] [![Latest release][releases]][releases] [![Coverage][codecov-badge]][codecov] [![Foundry][foundry-badge]][foundry] [![Discord][discord-badge]][discord]

[gha]: https://github.com/marigoldlabs/fjord-token/actions
[gha-badge]: https://github.com/marigoldlabs/fjord-token/actions/workflows/ci.yml/badge.svg
[releases]: https://img.shields.io/github/v/release/marigoldlabs/fjord-token
[releases-badge]: https://github.com/marigoldlabs/fjord-token/releases/latest
[codecov]: https://codecov.io/gh/marigoldlabs/fjord-token
[codecov-badge]: https://codecov.io/gh/marigoldlabs/fjord-token/graph/badge.svg?token=M4BYUMjKAR
[discord]: https://discord.gg/fjordfoundry
[discord-badge]: https://dcbadge.limes.pink/api/server/fjordfoundry?style=flat
[foundry]: https://getfoundry.sh
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

> Fjord Token, with a max supply of 100,000,000, operates on mainnet, offering staking options with vested earnings and penalties, alongside a dynamic revenue aggregation system. Its staking interface allows users to effortlessly manage staked tokens, claim rewards, and stay updated on FJORD token metrics and performance indicators.

## Install
```sh
git clone git@github.com:marigoldlabs/fjord-token.git
cd fjord-token
cp -iv .env.example .env
make init
```
Make sure to fill the `.env` API KEYs

## Tests
```sh
# test all without via-ir
make test
# gas-report and snapshot with via-ir
make test-gas
```

## Coverage
```sh
make coverage
```

## Deployment
Anvil localhost `make fork`

> Fjord(FJO) Token
```sh
make deploy-token c=sepolia
make deploy-token c=arbitrum_sepolia
make deploy-token c=mainnet
```

>Fjord Staking
### Deploy params
```
FJO_ADDRESS - Address of Fjord Token
SABLIERV2_LOCKUPLINEAR - Address of Sablier stream smart contract
AUTHORIZED_SENDER - Address of the owner whose cancellable streams will be accepted
```
```sh
make deploy-staking c=sepolia
make deploy-staking c=arbitrum_sepolia
make deploy-staking c=mainnet
```

## Documentation
All user and technical documentations are listed in the [/doc](/docs) folder.

## Audits

[find all audits here](./docs/audit/)

## Contributing

If you’re interested in contributing please see our [contribution guidelines](./CONTRIBUTING.md)

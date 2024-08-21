# Fjord Token Staking
![Test smart contracts](https://github.com/marigoldlabs/fjord-token/actions/workflows/ci.yml/badge.svg)

Thank you for your interest in contributing to Fjord Token Staking! There are many ways to contribute, and we appreciate all of them.

The contracts in this repo are in audited - we are releasing the code now for transparency, with open feedback and we appreciate any kind of contribution, no matter how small.

If you are looking to contribut to Fjord Frontend, please check this [repository](https://github.com/marigoldlabs/fjord-frontend)

## Contributing

If you’re interested in contributing please see our [contribution guidelines](./CONTRIBUTING.md)!

## Security Issues

If you discover a security issue, please bring it to our attention right away! Please **DO NOT** file a public issue, instead send your report privately to github AT marigoldlabs DOT xyz.

Security reports are greatly appreciated and we will publicly thank you for it. WIP Bug bounty

## Bug Reports

While bugs are unfortunate, they're a reality in software. We can't fix what we don't know about, so please report liberally. If you're not sure if something is a bug or not, feel free to file a bug anyway.

Opening an issue is as easy as following [this link](https://github.com/marigoldlabs/fjord-token/issues/new) and filling out the fields. Here are some things you can write about your bug:

- A short summary
- What did you try, step by step?
- What did you expect?
- What did happen instead?

## Pull Requests

Please keep in mind that:

- PR and commit should follow the [conventional commits][convcom]
- solidity file should contain the `// SPDX-License-Identifier: AGPL-3.0-only` or equivalent one.
- Pull-Requests point to the `master` branch
- You need to cover your code and feature by tests
- You may add documentation in the `/docs` directory to explain your choices if needed
- you do need to `make build`, `make fmt` and `make test` to submit a PR

### Workflow

Pull requests are the primary mechanism we use to change Fjord. GitHub itself has some [great documentation][pr] on using the Pull Request feature. We use the _fork and pull_ model described there.

#### Step 1: Fork

Fork the project on GitHub

```sh
git clone github.com/marigoldlabs/fjord-token.git
cd fjord-token
git remote add fork git://github.com/mmarigoldlabs/fjord-token.git
```

#### Step 2: Branch

Create a branch and lfg! :

```sh
git checkout -b my-branch origin/master
```

#### Step 3: Code

Well, we think you know how to do that. Just be sure to follow the coding best practices.

#### Step 4: Test

Don't forget to add tests and be sure they are all good:

```sh
cd fjord-token
make test
make test-gas
```

#### Step 5: Commit

Writing [good commit messages][convcom] is important. A commit message should describe what changed and why.

#### Step 6: Rebase

Use `git rebase` (_not_ `git merge`) to sync your work from time to time.

```sh
git fetch origin
git rebase origin/master my-branch
```

#### Step 7: Push

```sh
git push -u fork my-branch
```

Go to https://github.com/yourusername/fjord-contracts and select your branch. Click the 'Pull Request' button and fill out the form.

Alternatively, you can use [hub][hub] to open the pull request from your terminal:

```sh
git pull-request -b master -m "My PR message" -o
```

Pull requests are usually reviewed within a few days. If there are comments to address, apply your changes in a separate commit and push that to your branch. Post a comment in the pull request afterwards; GitHub doesn't send out notifications when you add commits.

## Whitepaper

## Architecture

## Repository Structure

All contracts are held within the `src/` folder.
All foundry tests are in the `test/forge/` folder.
All foundry cast are in the `test/sh` folder.

```markdown
󱧼 src
├──  FjordStaking.sol
└──  FjordToken.sol
```

```markdown
 test
├──  .DS_Store
├──  FjordStakingBase.t.sol
├──  fuzz
│   ├──  fuzzInstantUnstake.t.sol
│   ├──  fuzzStake.t.sol
│   └──  fuzzStakeVested.t.sol
├──  integration
│   ├──  bothClaim.t.sol
│   ├──  bothStake.t.sol
│   ├──  bothUnstake.t.sol
│   ├──  stakeReward.t.sol
│   ├──  stakeUnstake.t.sol
│   └──  vestStake.t.sol
├──  invariant
│   ├──  handler
│   │   ├──  BaseHandler.sol
│   │   ├──  LimitedStakeHandler.sol
│   │   └──  StakeHandler.sol
│   ├──  invariantStakeReward.t.sol
│   ├──  invariantTotalStake.t.sol
│   └──  invariantUserStake.t.sol
├──  security
│   ├──  SecurityCheckList.md
│   └──  TestHedgyFlashLoan.t.sol
└──  unit
    ├──  addReward.t.sol
    ├──  authorisedSender.t.sol
    ├──  claimReward.t.sol
    ├──  completeReceipt.t.sol
    ├──  constructor.t.sol
    ├──  epoch.t.sol
    ├──  sablierCancel.t.sol
    ├──  setRewardAdmin.t.sol
    ├──  stake.t.sol
    ├──  stakeVested.t.sol
    ├──  unstake.t.sol
    ├──  unstakeAll.t.sol
    ├──  unstakeInstant.t.sol
    └──  unstakeVested.t.sol
```

## Deployment and Usage
See readme

## License

All smart contracts are under GNU AFFERO GENERAL PUBLIC LICENSE

## Community

You can help us by making our community even more vibrant. For example, you can write a blog post, take some videos, answer the questions on [the discord](), post new tweets, and speak about what you like in Fjord!

[convcom]: https://www.conventionalcommits.org/en/
[pr]: https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests
[hub]: https://hub.github.com/
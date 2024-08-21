# Analysis

- Fjord Staking is a life-time running contract.
- In any case, user must have the right to withdraw principal amount as long as unlockTime is passed.
- Any emergency exit could be a big threat to bypass unlockTime or fund drained.
- Reward per token can't exceed actual added reward.
- `_checkEpochRollover` and `redeem` must be is idempotent, so if an reentrancy attack happen, state can't change twice because of these two function
- For each entrancy attack, unstake must be the target, either state fail to update or state mis-calculation lead to fund drained
- Fjord staking must not allow any external contract called except transfer FJO or sablier NFT
- No matter how much the attack loan, we need to make sure the state change match with the token flow. If they put in X amount of token, state change only corresponding with X amount. Same apply for Y
- In Fjord Staking, one transaction wouldn't effect the Reward Per Token, totalStaked, totalVestedStaked or UserData.totalStaked twice

---

# Security checklist

- [ ] Denial of Service (DoS)
- [x] Bad Randomness (BR): no random
- [x] Reentrancy (RE)

  - [x] Attack from hook function
    - [x] Fjord Token: no hook
    - [x] Sablier: need to check \_checkOnERC721Received: not invoked
    - [x] Sablier: need to check \_beforeTokenTransfer: not implemented
    - [x] Sablier: need to check \_afterTokenTransfer: not implemented
    - [x] Sablier: onWithdrawnHook: restricted staking nft
    - [x] Sablier: onCanceledHook: restricted staking nft
  - [x] Drain fjord token from unstake
  - [x] Drain fjord token from unstake vest
  - [x] Reward per token miscaculation
    - [x] `pendingRewards` is higher than the actual reward
  - [x] State update mismatch
    - [x] `totalStaked`
    - [x] `totalVestedStaked`
    - [x] `newStaked`
    - [x] `newVestedStaked`
    - [x] `totalRewards`
    - [x] `UserData`
    - [x] `DepositReceipt`
  - [x] List all possible callback scenarios: so far none

- [x] Flashloan (FL)
  - [x] Immediate Unstake after Stake
  - [x] Reward per token miscaculation
  - [x] State update mismatch
- [x] Attacks such as Integer Overflow (IO)

  - [x] Reward (`pendingRewards`) calculation
  - [x] Unstake calculation

- [ ] Improper Authentication (IA)
- [ ] Call Injection (CI)
- [ ] and Call-after-destruct (CAD)

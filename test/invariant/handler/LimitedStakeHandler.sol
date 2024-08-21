// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "./StakeHandler.sol";

contract LimitedStakeHandler is StakeHandler {
    constructor(FjordStaking _fjordStaking, MockERC20 _token) StakeHandler(_fjordStaking, _token) { }

    function stake(uint256 _amount, uint256 _timeJumpSeed) public override limitStakers {
        super.stake(_amount, _timeJumpSeed);
    }

    function unstake(uint16 _epoch, uint256 _amount, uint256 _timeJumpSeed)
        public
        override
        limitStakers
    {
        super.unstake(_epoch, _amount, _timeJumpSeed);
    }

    function addReward(uint256 _amount, uint256 _timeJumpSeed) public override {
        super.addReward(_amount, _timeJumpSeed);
    }
}

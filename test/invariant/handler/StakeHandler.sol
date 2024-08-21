// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "./BaseHandler.sol";

contract StakeHandler is BaseHandler {
    constructor(FjordStaking _fjordStaking, MockERC20 _token) BaseHandler(_fjordStaking, _token) { }

    function stake(uint256 _amount, uint256 _timeJumpSeed)
        public
        virtual
        instrument("stake")
        adjustTimestamp(_timeJumpSeed)
        bypassFjordStaking
    {
        _amount = bound(_amount, 1, 100_000_000 ether);
        deal(address(token), address(msg.sender), _amount);

        vm.startPrank(msg.sender);
        token.approve(address(fjordStaking), _amount);
        fjordStaking.stake(_amount);
        vm.stopPrank();
    }

    function unstake(uint16 _epoch, uint256 _amount, uint256 _timeJumpSeed)
        public
        virtual
        instrument("unstake")
        adjustTimestamp(_timeJumpSeed)
        bypassFjordStaking
    {
        _epoch = uint16(bound(_epoch, 0, fjordStaking.currentEpoch()));
        if (fjordStaking.currentEpoch() < 6 || _epoch > fjordStaking.currentEpoch() - 6) {
            return;
        }
        (uint16 epoch, uint256 staked,) = fjordStaking.deposits(address(msg.sender), _epoch);
        if (epoch == 0 || staked == 0) {
            return;
        }
        _amount = bound(_amount, 1, staked);
        vm.prank(address(msg.sender));
        fjordStaking.unstake(_epoch, _amount);
    }

    function addReward(uint256 _amount, uint256 _timeJumpSeed)
        public
        virtual
        instrument("addReward")
        adjustTimestamp(_timeJumpSeed)
    {
        if (msg.sender != fjordStaking.rewardAdmin()) {
            return;
        }
        _amount = bound(_amount, 1, 100_000_000 ether);
        deal(address(token), address(msg.sender), _amount);

        vm.startPrank(msg.sender);
        token.approve(address(fjordStaking), _amount);
        fjordStaking.addReward(_amount);
        vm.stopPrank();

        addedRewardAmount += _amount;
    }

    function claimReward(bool _isClaimEarly, uint256 _timeJumpSeed)
        public
        virtual
        instrument("claimReward")
        adjustTimestamp(_timeJumpSeed)
    {
        (, uint256 unclaimedRewards,,) = fjordStaking.userData(msg.sender);
        if (unclaimedRewards == 0) {
            return;
        }

        (uint16 requestedEpoch,) = fjordStaking.claimReceipts(address(this));
        if (requestedEpoch > 0 || requestedEpoch >= fjordStaking.currentEpoch() - 1) {
            return;
        }
        vm.prank(msg.sender);
        (uint256 rewardAmount,) = fjordStaking.claimReward(_isClaimEarly);
        earlyClaimAmount += rewardAmount;
    }

    function completeClaimRequest(uint256 _timeJumpSeed)
        public
        virtual
        instrument("completeClaimRequest")
        adjustTimestamp(_timeJumpSeed)
    {
        (uint16 requestedEpoch,) = fjordStaking.claimReceipts(address(this));
        if (requestedEpoch < 1 || fjordStaking.currentEpoch() - requestedEpoch <= 3) {
            return;
        }
        vm.prank(msg.sender);
        (uint256 rewardAmount) = fjordStaking.completeClaimRequest();
        fullClaimAmount += rewardAmount;
    }
}

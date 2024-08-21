// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../../../src/FjordStaking.sol";
import { FjordPoints } from "../../../src/FjordPoints.sol";
import "forge-std/console2.sol";

import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

contract PointHandler is CommonBase, StdCheats, StdUtils {
    FjordStaking public fjordStaking;
    FjordPoints public fjordPoints;

    uint256 public totalStaked;
    uint256 public totalPoints;
    address[] public stakers;
    mapping(address => bool) public isStaked;

    /// @dev Maps function names to the number of times they have been called.
    mapping(string func => uint256 calls) public calls;

    /// @dev The total number of calls made to this contract.
    uint256 public totalCalls;

    constructor(FjordStaking _fjordStaking, FjordPoints _fjordPoints) {
        fjordStaking = _fjordStaking;
        fjordPoints = _fjordPoints;
    }

    modifier bypassInvalidAddress(address _user) {
        if (_user == address(fjordPoints)) {
            return;
        }
        if (_user == address(0)) {
            return;
        }
        _;
    }

    /// @param _timeJumpSeed A fuzzed value needed for generating random time warps.
    modifier adjustTimestamp(uint256 _timeJumpSeed) {
        uint256 timeJump = _bound(_timeJumpSeed, 2 minutes, 1 weeks);
        uint256 nextTime = vm.getBlockTimestamp() + timeJump;
        vm.warp(nextTime);
        _;
    }

    /// @dev Records a function call for instrumentation purposes.
    modifier instrument(string memory _functionName) {
        calls[_functionName]++;
        totalCalls++;
        _;
    }

    /// @dev records the staker
    function recordOnStaker(address user) public {
        if (!isStaked[user]) {
            stakers.push(user);
            isStaked[user] = true;
        }
    }

    function getRandomStaker() public view returns (address, bool) {
        if (stakers.length == 0) {
            return (address(0), false);
        }
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        return (stakers[random % stakers.length], true);
    }

    function onStaked(address _user, uint256 _amount, uint256 _timeJumpSeed)
        public
        instrument("onStaked")
        adjustTimestamp(_timeJumpSeed)
        bypassInvalidAddress(_user)
    {
        recordOnStaker(_user);
        _amount = bound(_amount, 1, 100_000_000 ether);
        vm.prank(address(fjordStaking));
        fjordPoints.onStaked(_user, _amount);
        totalStaked += _amount;
    }

    function onUnstaked(uint256 _amount, uint256 _timeJumpSeed)
        public
        instrument("onUnstaked")
        adjustTimestamp(_timeJumpSeed)
    {
        (address staker, bool isOk) = getRandomStaker();
        if (!isOk) {
            return;
        }
        (uint256 stakedAmount,,) = fjordPoints.users(staker);
        if (stakedAmount == 0) {
            return;
        }
        _amount = bound(_amount, 1, stakedAmount);
        vm.prank(address(fjordStaking));
        fjordPoints.onUnstaked(staker, _amount);
        totalStaked -= _amount;
    }

    function distributePoints(uint256 _timeJumpSeed)
        public
        instrument("distributePoints")
        adjustTimestamp(_timeJumpSeed)
    {
        if (block.timestamp < fjordPoints.lastDistribution() + fjordPoints.EPOCH_DURATION()) {
            return;
        }

        if (fjordPoints.totalStaked() == 0) {
            return;
        }
        fjordPoints.distributePoints();
    }

    function claimPoints(uint256 _timeJumpSeed)
        public
        instrument("claimPoints")
        adjustTimestamp(_timeJumpSeed)
    {
        (address staker, bool isOk) = getRandomStaker();
        if (!isOk) {
            return;
        }
        uint256 balanceBefore = fjordPoints.balanceOf(staker);
        vm.prank(staker);
        fjordPoints.claimPoints();
        uint256 balanceAfter = fjordPoints.balanceOf(staker);
        totalPoints += (balanceAfter - balanceBefore);
    }
}

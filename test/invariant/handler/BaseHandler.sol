// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../../../src/FjordStaking.sol";
import "forge-std/console.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

import { CommonBase } from "forge-std/Base.sol";
import { StdCheats } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";

contract BaseHandler is CommonBase, StdCheats, StdUtils {
    FjordStaking public fjordStaking;
    MockERC20 public token;
    uint256 public constant MAX_TARGET_SENDERS = 50;
    uint256 public addedRewardAmount = 0;
    uint256 public earlyClaimAmount = 0;
    uint256 public fullClaimAmount = 0;
    address[] public stakers;
    mapping(address => bool) public isStaked;

    /// @dev Maps function names to the number of times they have been called.
    mapping(string func => uint256 calls) public calls;

    /// @dev The total number of calls made to this contract.
    uint256 public totalCalls;

    constructor(FjordStaking _fjordStaking, MockERC20 _token) {
        fjordStaking = _fjordStaking;
        token = _token;
    }

    modifier bypassFjordStaking() {
        if (msg.sender == address(fjordStaking)) {
            return;
        }
        _;
    }

    modifier limitStakers() {
        if (stakers.length >= MAX_TARGET_SENDERS && !isStaked[msg.sender]) {
            return;
        }
        _;
        if (isStaked[msg.sender]) {
            return;
        }
        stakers.push(msg.sender);
        isStaked[msg.sender] = true;
    }

    /// @param _timeJumpSeed A fuzzed value needed for generating random time warps.
    modifier adjustTimestamp(uint256 _timeJumpSeed) {
        uint256 timeJump = _bound(_timeJumpSeed, 2 minutes, 7 weeks);
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

    function getStakersLength() public view returns (uint256) {
        return stakers.length;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../src/FjordStaking.sol";
import { FjordPoints } from "../src/FjordPoints.sol";
import { Test } from "forge-std/Test.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { FjordPointsMock } from "./mocks/FjordPointsMock.sol";
import { ISablierV2LockupLinear } from "lib/v2-core/src/interfaces/ISablierV2LockupLinear.sol";
import { ISablierV2Lockup } from "lib/v2-core/src/interfaces/ISablierV2Lockup.sol";
import { Broker, LockupLinear } from "lib/v2-core/src/types/DataTypes.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import "lib/v2-core/src/libraries/Errors.sol";

contract FjordStakingBase is Test {
    event Staked(address indexed user, uint16 indexed epoch, uint256 amount);
    event VestedStaked(
        address indexed user, uint16 indexed epoch, uint256 indexed streamID, uint256 amount
    );
    event RewardAdded(uint16 indexed epoch, address rewardAdmin, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event EarlyRewardClaimed(address indexed user, uint256 rewardAmount, uint256 penaltyAmount);

    event Unstaked(address indexed user, uint16 indexed epoch, uint256 stakedAmount);
    event VestedUnstaked(
        address indexed user, uint16 indexed epoch, uint256 stakedAmount, uint256 streamID
    );

    event ClaimReceiptCreated(address indexed user, uint16 requestEpoch);
    event UnstakedAll(
        address indexed user,
        uint256 totalStakedAmount,
        uint256[] activeDepositsBefore,
        uint256[] activeDepositsAfter
    );

    event RewardPerTokenChanged(uint16 epoch, uint256 rewardPerToken);

    event SablierWithdrawn(address indexed user, uint256 streamID, address caller, uint256 amount);

    event SablierCanceled(address indexed user, uint256 streamID, address caller, uint256 amount);

    uint256 constant addRewardPerEpoch = 1 ether;
    FjordStaking fjordStaking;
    MockERC20 token;
    address minter = makeAddr("minter");
    address newMinter = makeAddr("new_minter");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address internal constant SABLIER_ADDRESS = address(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);
    address points;
    bool isMock = true;

    ISablierV2LockupLinear SABLIER = ISablierV2LockupLinear(SABLIER_ADDRESS);
    address authorizedSender = address(this);
    bool isFuzzOrInvariant = false;

    function beforeSetup() internal virtual { }

    function afterSetup() internal virtual { }

    function setUp() public {
        beforeSetup();

        if (!isFuzzOrInvariant) {
            vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 19_595_905 });
        }

        if (isMock) {
            points = address(new FjordPointsMock());
        } else {
            points = address(new FjordPoints());
        }

        token = new MockERC20("Fjord", "FJO", 18);
        fjordStaking =
            new FjordStaking(address(token), minter, SABLIER_ADDRESS, authorizedSender, points);

        deal(address(token), address(this), 10000 ether);
        token.approve(address(fjordStaking), 10000 ether);

        deal(address(token), minter, 10000 ether);
        vm.prank(minter);
        token.approve(address(fjordStaking), 10000 ether);

        deal(address(token), alice, 10000 ether);
        vm.prank(alice);
        token.approve(address(fjordStaking), 10000 ether);

        afterSetup();
    }

    function _addRewardAndEpochRollover(uint256 reward, uint256 times) internal returns (uint16) {
        vm.startPrank(minter);
        for (uint256 i = 0; i < times; i++) {
            vm.warp(vm.getBlockTimestamp() + fjordStaking.epochDuration());
            fjordStaking.addReward(reward);
        }
        vm.stopPrank();
        return fjordStaking.currentEpoch();
    }

    function createStream() internal returns (uint256 streamID) {
        return createStream(address(this), token, false, 100 ether);
    }

    function createStream(MockERC20 asset, bool isCancelable) internal returns (uint256 streamID) {
        return createStream(address(this), asset, isCancelable, 100 ether);
    }

    function createStream(address sender, MockERC20 asset, bool isCancelable)
        internal
        returns (uint256 streamID)
    {
        return createStream(sender, asset, isCancelable, 100 ether);
    }

    function createStream(address sender, MockERC20 asset, bool isCancelable, uint256 amount)
        internal
        returns (uint256 streamID)
    {
        deal(address(asset), sender, amount);
        vm.prank(sender);
        asset.approve(address(SABLIER), amount);

        LockupLinear.CreateWithRange memory params;

        params.sender = sender;
        params.recipient = alice;
        params.totalAmount = uint128(amount);
        params.asset = IERC20(address(asset));
        params.cancelable = isCancelable;
        params.range = LockupLinear.Range({
            start: uint40(vm.getBlockTimestamp() + 1 days),
            cliff: uint40(vm.getBlockTimestamp() + 2 days),
            end: uint40(vm.getBlockTimestamp() + 11 days)
        });
        params.broker = Broker(address(0), ud60x18(0));
        vm.prank(sender);
        streamID = SABLIER.createWithRange(params);
    }

    function createStreamAndStake() internal returns (uint256 streamID) {
        return createStreamAndStake(address(this), false, 10 ether);
    }

    function createStreamAndStake(bool cancelable) internal returns (uint256 streamID) {
        return createStreamAndStake(address(this), cancelable, 10 ether);
    }

    function createStreamAndStake(address sender, bool cancelable)
        internal
        returns (uint256 streamID)
    {
        return createStreamAndStake(sender, cancelable, 10 ether);
    }

    function createStreamAndStake(address sender, bool cancelable, uint256 amount)
        internal
        returns (uint256 streamID)
    {
        streamID = createStream(sender, token, cancelable, amount);

        vm.startPrank(alice);
        SABLIER.approve(address(fjordStaking), streamID);
        uint16 currentEpoch = fjordStaking.currentEpoch();
        vm.expectEmit();
        emit VestedStaked(alice, currentEpoch, streamID, amount);
        fjordStaking.stakeVested(streamID);

        vm.stopPrank();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../../src/FjordStaking.sol";
import { FjordPoints } from "../../src/FjordPoints.sol";
import "./handler/StakeHandler.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { FjordPointsMock } from "../mocks/FjordPointsMock.sol";

contract InvariantStakingPoint is Test {
    FjordStaking private fjordStaking;
    FjordPoints private fjordPoints;
    MockERC20 private token;
    MockERC20 private auctionToken;
    StakeHandler private stakeHandler;
    address minter = makeAddr("minter");
    address private constant SABLIER_ADDRESS = address(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);
    uint256 firstDistribution;

    function setUp() public {
        token = new MockERC20("Fjord", "FJO", 18);
        auctionToken = new MockERC20("Reward XYZ Token", "RXT", 18);
        fjordPoints = new FjordPoints();
        fjordStaking = new FjordStaking(
            address(token), minter, SABLIER_ADDRESS, address(this), address(fjordPoints)
        );
        fjordPoints.setStakingContract(address(fjordStaking));
        firstDistribution = fjordPoints.lastDistribution();

        stakeHandler = new StakeHandler(fjordStaking, token);
        // Target the StakeHandler contract for fuzzing
        targetContract(address(stakeHandler));
        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = stakeHandler.stake.selector;
        selectors[1] = stakeHandler.unstake.selector;
        selectors[2] = stakeHandler.addReward.selector;
        selectors[3] = stakeHandler.claimReward.selector;
        selectors[4] = stakeHandler.completeClaimRequest.selector;
        targetSelector(FuzzSelector({ addr: address(stakeHandler), selectors: selectors }));
    }

    /// @dev invariant test total stake between staking and point contract
    function invariant_StakingPoint_TotalStake() public {
        assertEq(
            fjordPoints.totalStaked(),
            fjordStaking.totalStaked() + fjordStaking.newStaked(),
            "Invariant: total staked in Points and Staking is different"
        );
    }

    function invariant_StakingPoint_TotalPoints() public {
        uint256 totalWeeks =
            (fjordPoints.lastDistribution() - firstDistribution) / fjordPoints.EPOCH_DURATION();
        assertEq(
            fjordPoints.totalPoints(),
            fjordPoints.pointsPerEpoch() * totalWeeks,
            "Invariant: total points release is not correct"
        );
    }
}

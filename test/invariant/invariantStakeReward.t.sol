// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../../src/FjordStaking.sol";
import "./handler/StakeHandler.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { FjordPointsMock } from "../mocks/FjordPointsMock.sol";

contract InvariantTest is Test {
    FjordStaking private fjordStaking;
    MockERC20 private token;
    StakeHandler private stakeHandler;
    address minter = makeAddr("minter");
    address private constant SABLIER_ADDRESS = address(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);

    function setUp() public {
        token = new MockERC20("Fjord", "FJO", 18);
        fjordStaking = new FjordStaking(
            address(token), minter, SABLIER_ADDRESS, address(this), address(new FjordPointsMock())
        );
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

    /// @dev Invariant test to ensure the total staked tokens match the token balance of the staking contract
    function invariant_StakeAndReward() public {
        // Retrieve total staked and new staked values
        (uint256 totalStaked, uint256 newStaked) =
            (fjordStaking.totalStaked(), fjordStaking.newStaked());
        uint256 tokenBalance = token.balanceOf(address(fjordStaking));
        // Ensure token balance matches the total of staked and newly staked tokens
        assertEq(
            tokenBalance,
            totalStaked + newStaked + stakeHandler.addedRewardAmount()
                - stakeHandler.earlyClaimAmount() - stakeHandler.fullClaimAmount(),
            "Invariant: Total staked + new staked equal to token balance"
        );
    }
}

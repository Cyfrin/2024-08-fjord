// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.21;

import "../../src/FjordStaking.sol";
import "./handler/PointHandler.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract InvariantTotalPoints is Test {
    FjordStaking private fjordStaking;
    FjordPoints private fjordPoints;
    MockERC20 private token;
    PointHandler private pointHandler;

    address minter = makeAddr("minter");
    address private constant SABLIER_ADDRESS = address(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);

    function setUp() public {
        token = new MockERC20("Fjord", "FJO", 18);
        fjordPoints = new FjordPoints();
        fjordStaking = new FjordStaking(
            address(token), minter, SABLIER_ADDRESS, address(this), address(fjordPoints)
        );
        fjordPoints.setStakingContract(address(fjordStaking));

        pointHandler = new PointHandler(fjordStaking, fjordPoints);
        targetContract(address(pointHandler));
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = pointHandler.onStaked.selector;
        selectors[1] = pointHandler.onUnstaked.selector;
        selectors[2] = pointHandler.distributePoints.selector;
        selectors[3] = pointHandler.claimPoints.selector;
        targetSelector(FuzzSelector({ addr: address(pointHandler), selectors: selectors }));
    }

    /// @dev Invariant test to ensure the total staked tokens match the token balance of the staking contract
    function invariant_TotalPoint() public {
        // Retrieve total staked and new staked values
        (uint256 expectedTotalStaked, uint256 expectedTotalPoints) =
            (pointHandler.totalStaked(), pointHandler.totalPoints());
        uint256 givenTotalStaked = fjordPoints.totalStaked();
        uint256 givenTotalPoints = fjordPoints.totalSupply();
        // Ensure token balance matches the total of staked and newly staked tokens
        assertEq(
            givenTotalStaked,
            expectedTotalStaked,
            "Invariant: total staked tokens do not match the token balance of the point contract"
        );
        assertEq(
            givenTotalPoints,
            expectedTotalPoints,
            "Invariant: total points do not match the token balance of the point contract"
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "forge-std/Test.sol";
import "src/FjordPoints.sol";
import { SafeMath } from "lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";

contract TestFjordPoints is Test {
    using SafeMath for uint256;

    FjordPoints public fjordPoints;
    address public staking = address(0x1);

    function setUp() public {
        fjordPoints = new FjordPoints();
        fjordPoints.setStakingContract(staking);
    }

    function testInitialSetup() public {
        assertEq(fjordPoints.name(), "BjordBoint");
        assertEq(fjordPoints.symbol(), "BJB");
        assertEq(fjordPoints.staking(), staking);
    }

    function testSetOwnerCallerDisallowed() public {
        vm.prank(staking);
        vm.expectRevert(FjordPoints.CallerDisallowed.selector);
        fjordPoints.setOwner(address(0));
    }

    function testSetOwnerInvalidAddress() public {
        vm.expectRevert(FjordPoints.InvalidAddress.selector);
        fjordPoints.setOwner(address(0));
    }

    function testSetOwner() public {
        fjordPoints.setOwner(address(0x1));
    }

    function testStakingInvalidAddress() public {
        vm.expectRevert(FjordPoints.InvalidAddress.selector);
        fjordPoints.setStakingContract(address(0));
    }

    function testSetPointsPerEpochZeroValue() public {
        vm.expectRevert();
        fjordPoints.setPointsPerEpoch(0);
    }

    function testSetPointsPerEpoch() public {
        assertEq(fjordPoints.pointsPerEpoch(), 100 ether);

        fjordPoints.setPointsPerEpoch(1 ether);

        assertEq(fjordPoints.pointsPerEpoch(), 1 ether);
    }

    function testStakeTokens() public {
        address user = address(0x2);
        uint256 amount = 1000 ether;

        vm.startPrank(staking);
        fjordPoints.onStaked(user, amount);
        vm.stopPrank();

        (uint256 stakedAmount,,) = fjordPoints.users(user);

        assertEq(stakedAmount, amount);
        assertEq(fjordPoints.totalStaked(), amount);
    }

    function testUnstakeTokensAmountExceeds() public {
        address user = address(0x2);
        uint256 amount = 1000 ether;

        vm.startPrank(staking);
        fjordPoints.onStaked(user, amount);

        vm.expectRevert(FjordPoints.UnstakingAmountExceedsStakedAmount.selector);
        fjordPoints.onUnstaked(user, amount * 2);
        vm.stopPrank();
    }

    function testUnstakeTokens() public {
        address user = address(0x2);
        uint256 amount = 1000 ether;

        vm.startPrank(staking);
        fjordPoints.onStaked(user, amount);
        fjordPoints.onUnstaked(user, amount / 2);
        vm.stopPrank();

        (uint256 stakedAmount,,) = fjordPoints.users(user);

        assertEq(stakedAmount, amount / 2);
        assertEq(fjordPoints.totalStaked(), amount / 2);
    }

    function testDistributePoints() public {
        address user = address(0x2);
        uint256 stakeAmount = 1000 ether;
        uint256 points = fjordPoints.pointsPerEpoch();

        vm.startPrank(staking);
        fjordPoints.onStaked(user, stakeAmount);
        vm.stopPrank();

        skip(1 weeks);

        fjordPoints.distributePoints();

        uint256 expectedPoints = points.mul(1e18).div(stakeAmount);
        assertEq(fjordPoints.pointsPerToken(), expectedPoints);
    }

    function testDistributePointsAfter2Weeks() public {
        address user = address(0x2);
        uint256 stakeAmount = 1000 ether;
        uint256 points = fjordPoints.pointsPerEpoch();

        vm.startPrank(staking);
        fjordPoints.onStaked(user, stakeAmount);
        vm.stopPrank();

        skip(2 weeks);

        fjordPoints.distributePoints();

        uint256 expectedPoints = 2 * points.mul(1e18).div(stakeAmount);
        assertEq(fjordPoints.pointsPerToken(), expectedPoints);
    }

    function testClaimPoints() public {
        address user = address(0x2);
        uint256 stakeAmount = 1000 ether;
        uint256 points = fjordPoints.pointsPerEpoch();

        vm.startPrank(staking);
        fjordPoints.onStaked(user, stakeAmount);
        vm.stopPrank();

        skip(1 weeks);

        fjordPoints.distributePoints();

        vm.prank(user);
        fjordPoints.claimPoints();

        uint256 expectedPoints = stakeAmount.mul(points).div(fjordPoints.totalStaked());
        assertEq(fjordPoints.balanceOf(user), expectedPoints);
    }

    function testUnauthorizedStaking() public {
        address user = address(0x2);
        uint256 amount = 1000 ether;

        vm.expectRevert(FjordPoints.NotAuthorized.selector);
        fjordPoints.onStaked(user, amount);
    }

    function testZeroStakeAndUnstake() public {
        address user = address(0x2);

        vm.startPrank(staking);
        fjordPoints.onStaked(user, 0);
        fjordPoints.onUnstaked(user, 0);
        vm.stopPrank();

        (uint256 stakedAmount,,) = fjordPoints.users(user);

        assertEq(stakedAmount, 0);
        assertEq(fjordPoints.totalStaked(), 0);
    }

    function testDistributePointsWithNoStake() public {
        skip(1 weeks);

        fjordPoints.distributePoints();
        assertEq(fjordPoints.pointsPerToken(), 0);
    }

    function testClaimPointsWithNoDistribution() public {
        address user = address(0x2);
        uint256 stakeAmount = 1000 ether;

        vm.startPrank(staking);
        fjordPoints.onStaked(user, stakeAmount);
        vm.stopPrank();

        vm.prank(user);
        fjordPoints.claimPoints();

        assertEq(fjordPoints.balanceOf(user), 0);
    }
}

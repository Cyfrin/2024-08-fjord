// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract PointsIntegrationTest is FjordStakingBase {
    FjordPoints POINTS;

    function beforeSetup() internal override {
        isMock = false;
    }

    function afterSetup() internal override {
        POINTS = FjordPoints(points);
        POINTS.setStakingContract(address(fjordStaking));
    }

    function test_Stake_Amount_Accumulate() public {
        fjordStaking.stake(1 ether);

        (uint256 stakedAmount, uint256 pendingPoints, uint256 lastPointsPerToken) =
            POINTS.users(address(this));

        assertEq(stakedAmount, 1 ether);
        assertEq(pendingPoints, 0);
        assertEq(lastPointsPerToken, 0);
    }

    function test_Points_Accumulate() public {
        fjordStaking.stake(1 ether);

        vm.warp(vm.getBlockTimestamp() + POINTS.EPOCH_DURATION());
        POINTS.distributePoints();

        fjordStaking.stake(1 ether);

        (uint256 stakedAmount, uint256 pendingPoints, uint256 lastPointsPerToken) =
            POINTS.users(address(this));

        assertEq(stakedAmount, 2 ether);
        assertEq(pendingPoints, 100 ether);
        assertEq(lastPointsPerToken, 100 ether);
    }

    function test_Points_Accumulate_2_Users() public {
        fjordStaking.stake(1 ether);

        vm.prank(alice);
        fjordStaking.stake(1 ether);

        vm.warp(vm.getBlockTimestamp() + POINTS.EPOCH_DURATION());
        POINTS.distributePoints();

        fjordStaking.stake(1 ether);

        vm.prank(alice);
        fjordStaking.stake(1 ether);

        (uint256 stakedAmount, uint256 pendingPoints, uint256 lastPointsPerToken) =
            POINTS.users(address(this));

        assertEq(stakedAmount, 2 ether);
        assertEq(pendingPoints, 50 ether);
        assertEq(lastPointsPerToken, 50 ether);

        (uint256 stakedAmountA, uint256 pendingPointsA, uint256 lastPointsPerTokenA) =
            POINTS.users(alice);

        assertEq(stakedAmountA, 2 ether);
        assertEq(pendingPointsA, 50 ether);
        assertEq(lastPointsPerTokenA, 50 ether);
    }

    function test_Points_Accumulate_2_Epochs() public {
        fjordStaking.stake(1 ether);

        vm.warp(vm.getBlockTimestamp() + POINTS.EPOCH_DURATION());
        POINTS.distributePoints();

        vm.prank(alice);
        fjordStaking.stake(1 ether);

        (uint256 stakedAmountA, uint256 pendingPointsA, uint256 lastPointsPerTokenA) =
            POINTS.users(alice);

        assertEq(stakedAmountA, 1 ether);
        assertEq(pendingPointsA, 0);
        assertEq(lastPointsPerTokenA, 100 ether);
    }
}

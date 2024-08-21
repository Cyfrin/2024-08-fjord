// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract UnstakeInstant_Unit_Test is FjordStakingBase {
    function test_Unstake_Instant_Full() public {
        uint16 currentEpoch = fjordStaking.currentEpoch();
        fjordStaking.stake(1 ether);
        assertEq(fjordStaking.totalStaked(), 0);
        assertEq(fjordStaking.newStaked(), 1 ether);

        vm.expectEmit();
        emit Unstaked(address(this), currentEpoch, 1 ether);
        fjordStaking.unstake(currentEpoch, 1 ether);
        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 0);

        assertEq(fjordStaking.totalStaked(), 0);
        assertEq(fjordStaking.newStaked(), 0);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 0);
        assertEq(unclaimedRewards, 0);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 0);
    }

    function test_Unstake_Instant_Half() public {
        uint16 currentEpoch = fjordStaking.currentEpoch();
        fjordStaking.stake(1 ether);

        vm.expectEmit();
        emit Unstaked(address(this), currentEpoch, 0.5 ether);
        fjordStaking.unstake(currentEpoch, 0.5 ether);
        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 1);
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 0);
        assertEq(unclaimedRewards, 0);
        assertEq(unredeemedEpoch, 1);
        assertEq(lastClaimedEpoch, 0);

        vm.expectEmit();
        emit Unstaked(address(this), currentEpoch, 0.5 ether);
        fjordStaking.unstake(currentEpoch, 0.5 ether);
        activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 0);
        (totalStaked, unclaimedRewards, unredeemedEpoch, lastClaimedEpoch) =
            fjordStaking.userData(address(this));
        assertEq(totalStaked, 0);
        assertEq(unclaimedRewards, 0);
        assertEq(unredeemedEpoch, 0);
        assertEq(lastClaimedEpoch, 0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract Stake_Unit_Test is FjordStakingBase {
    function test_InvalidStakeAmount() public {
        vm.expectRevert(FjordStaking.InvalidAmount.selector);
        fjordStaking.stake(0);
    }

    function test_Stake() public {
        // Stake 1 ether
        fjordStaking.stake(1 ether);
        assertEq(token.balanceOf(address(fjordStaking)), 1 ether);
        (uint16 epoch, uint256 staked,) = fjordStaking.deposits(address(this), 1);
        // Should have 1 ether staked
        assertEq(staked, 1 ether);
        assertEq(epoch, 1);
        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 1);
        assertEq(activeDeposits[0], 1);

        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 0 ether);
        assertEq(unclaimedRewards, 0 ether);
        // epoch 1 not redeem yet
        assertEq(unredeemedEpoch, 1);
        assertEq(lastClaimedEpoch, 0);

        assertEq(fjordStaking.newStaked(), 1 ether);
        assertEq(fjordStaking.totalStaked(), 0);
    }

    function test_Stake_TwiceSameEpoch() public {
        // Stake 1 ether
        fjordStaking.stake(1 ether);
        // Stake another 2 ether
        fjordStaking.stake(2 ether);
        assertEq(token.balanceOf(address(fjordStaking)), 3 ether);
        (uint16 epoch, uint256 staked,) = fjordStaking.deposits(address(this), 1);
        // Should have 3 ether staked in the same epoch
        assertEq(staked, 3 ether);
        assertEq(epoch, 1);
        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 1);
        assertEq(activeDeposits[0], 1);

        // check user data, it only update to the first stake (second stake haven't count)
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 0 ether);
        assertEq(unclaimedRewards, 0 ether);
        assertEq(unredeemedEpoch, 1);
        assertEq(lastClaimedEpoch, 0);
    }

    function test_Stake_DifferentEpoch() public {
        // Stake 1 ether
        fjordStaking.stake(1 ether);
        // roll over to next epoch
        _addRewardAndEpochRollover(1 ether, 3);

        assertEq(fjordStaking.newStaked(), 0 ether);
        assertEq(fjordStaking.totalStaked(), 1 ether);

        assertEq(fjordStaking.currentEpoch(), 4);
        // Stake another 2 ether
        fjordStaking.stake(2 ether);
        // staked 3, added reward 3
        assertEq(token.balanceOf(address(fjordStaking)), 6 ether);
        (uint16 epoch, uint256 staked,) = fjordStaking.deposits(address(this), 4);
        // Should have 3 ether staked in the same epoch
        assertEq(staked, 2 ether);
        assertEq(epoch, 4);
        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(this));
        assertEq(activeDeposits.length, 2);
        assertEq(activeDeposits[0], 1);
        assertEq(activeDeposits[1], 4);

        // check user data, it only update to the first stake (second stake haven't count)
        (
            uint256 totalStaked,
            uint256 unclaimedRewards,
            uint16 unredeemedEpoch,
            uint16 lastClaimedEpoch
        ) = fjordStaking.userData(address(this));
        assertEq(totalStaked, 1 ether);
        assertEq(unclaimedRewards, 3 ether);
        // epoch 4 not redeem yet
        assertEq(unredeemedEpoch, 4);
        assertEq(lastClaimedEpoch, 3);
    }

    function test_Stake_EmitStakedEvent() public {
        vm.expectEmit();

        emit Staked(address(this), 1, 1 ether);
        fjordStaking.stake(1 ether);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../FjordStakingBase.t.sol";

contract BotUnstakeScenarios is FjordStakingBase {
    /*
    Scenarios: 
    - deposit with both stake and stakeVested
    - unstake normal
    - unstake vested
    */
    function test_BothStake_Unstake_Normal_Vested() public {
        // both stake
        uint256 streamID = createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Add 15 ether reward
        _addRewardAndEpochRollover(15 ether, 7);
        assertEq(fjordStaking.currentEpoch(), 8);

        // unstake normal
        vm.prank(alice);
        uint256 total = fjordStaking.unstake(1, 5 ether);

        assertEq(total, 5 ether);
        assertEq(fjordStaking.totalStaked(), 10 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 0 ether);
        assertEq(vestedStaked, 10 ether);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        (uint256 totalStaked,,, uint16 lastClaimedEpoch) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 10 ether);
        assertEq(lastClaimedEpoch, 7);

        // unstake vested
        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        assertEq(fjordStaking.totalStaked(), 0 ether);
        (epoch,, vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(vestedStaked, 0 ether);

        activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 0);

        (totalStaked,,,) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
    }
    /*
    Scenarios: 
    - deposit with both stake and stakeVested
    - unstake vested
    - unstake normal
    */

    function test_BothStake_Unstake_Vested_Normal() public {
        // both stake
        uint256 streamID = createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Add 15 ether reward
        _addRewardAndEpochRollover(15 ether, 7);
        assertEq(fjordStaking.currentEpoch(), 8);

        // unstake vested
        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        assertEq(fjordStaking.totalStaked(), 5 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 5 ether);
        assertEq(vestedStaked, 0 ether);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        (uint256 totalStaked,,, uint16 lastClaimedEpoch) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 5 ether);
        assertEq(lastClaimedEpoch, 7);

        // unstake normal
        vm.prank(alice);
        fjordStaking.unstake(1, 5 ether);

        assertEq(fjordStaking.totalStaked(), 0 ether);
        (epoch, staked,) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(staked, 0 ether);

        activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 0);

        (totalStaked,,,) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
    }
    /*
    Scenarios: 
    - deposit with both stake and stakeVested
    - unstake normal partial
    - unstake vested
    */

    function test_BothStake_Unstake_Normal_Partial_Vested() public {
        // both stake
        uint256 streamID = createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Add 15 ether reward
        _addRewardAndEpochRollover(15 ether, 7);
        assertEq(fjordStaking.currentEpoch(), 8);

        // unstake normal partial
        vm.prank(alice);
        uint256 total = fjordStaking.unstake(1, 2 ether);

        assertEq(total, 2 ether);
        assertEq(fjordStaking.totalStaked(), 13 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 3 ether);
        assertEq(vestedStaked, 10 ether);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        (uint256 totalStaked,,, uint16 lastClaimedEpoch) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 13 ether);
        assertEq(lastClaimedEpoch, 7);

        // unstake vested
        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        assertEq(fjordStaking.totalStaked(), 3 ether);
        (epoch, staked, vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 3 ether);
        assertEq(vestedStaked, 0 ether);

        activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        (totalStaked,,,) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 3 ether);
    }

    /*
    Scenarios: 
    - deposit with both stake and stakeVested
    - unstake vested
    - unstake normal partial
    */
    function test_BothStake_Unstake_Vested_Normal_Partial() public {
        // both stake
        uint256 streamID = createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Add 15 ether reward
        _addRewardAndEpochRollover(15 ether, 7);
        assertEq(fjordStaking.currentEpoch(), 8);

        // unstake vested
        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        assertEq(fjordStaking.totalStaked(), 5 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 5 ether);
        assertEq(vestedStaked, 0 ether);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        (uint256 totalStaked,,, uint16 lastClaimedEpoch) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 5 ether);
        assertEq(lastClaimedEpoch, 7);

        // unstake normal partial
        vm.prank(alice);
        fjordStaking.unstake(1, 2 ether);

        assertEq(fjordStaking.totalStaked(), 3 ether);
        (epoch, staked,) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 3 ether);

        activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        (totalStaked,,,) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 3 ether);
    }
    /*
    Scenarios: 
    - deposit with both stake and stakeVested
    - unstakeAll
    */

    function test_BothStake_Unstake_Vested_All() public {
        // both stake
        uint256 streamID = createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);
        _addRewardAndEpochRollover(15 ether, 1);
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Add 15 ether reward
        _addRewardAndEpochRollover(15 ether, 7);
        assertEq(fjordStaking.currentEpoch(), 9);

        // unstake vested
        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        assertEq(fjordStaking.totalStaked(), 10 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 5 ether);
        assertEq(vestedStaked, 0 ether);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 2);

        (uint256 totalStaked,,, uint16 lastClaimedEpoch) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 10 ether);
        assertEq(lastClaimedEpoch, 8);

        // unstake all
        vm.prank(alice);
        fjordStaking.unstakeAll();

        assertEq(fjordStaking.totalStaked(), 0 ether);
        (epoch, staked,) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(staked, 0 ether);
        (epoch, staked,) = fjordStaking.deposits(alice, 2);
        assertEq(epoch, 0);
        assertEq(staked, 0 ether);

        activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 0);

        (totalStaked,,,) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
    }

    /*
    Scenarios: 
    - deposit with both stake and stakeVested
    - unstakeAll
    */

    function test_BothStake_Unstake_All_Vested() public {
        // both stake
        uint256 streamID = createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);
        _addRewardAndEpochRollover(15 ether, 1);
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // Add 15 ether reward
        _addRewardAndEpochRollover(15 ether, 7);
        assertEq(fjordStaking.currentEpoch(), 9);

        // unstake all
        vm.prank(alice);
        fjordStaking.unstakeAll();

        assertEq(fjordStaking.totalStaked(), 10 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 0 ether);
        assertEq(vestedStaked, 10 ether);

        (epoch, staked,) = fjordStaking.deposits(alice, 2);
        assertEq(epoch, 0);
        assertEq(staked, 0 ether);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        (uint256 totalStaked,,, uint16 lastClaimedEpoch) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 10 ether);
        assertEq(lastClaimedEpoch, 8);

        // unstake vested
        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        assertEq(fjordStaking.totalStaked(), 0 ether);
        (epoch,, vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(vestedStaked, 0 ether);

        activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 0);

        (totalStaked,,,) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
    }
    /*
    Scenarios: 
    - deposit with both stake and stakeVested same epoch
    - unstake vested instant
    - unstake normal instant
    */

    function test_BothStake_Unstake_Vested_Normal_Instant() public {
        // both stake
        uint256 streamID = createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // unstake vested
        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        assertEq(fjordStaking.totalStaked(), 0 ether);
        assertEq(fjordStaking.newStaked(), 5 ether);

        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 5 ether);
        assertEq(vestedStaked, 0 ether);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        (uint256 totalStaked,,, uint16 lastClaimedEpoch) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
        assertEq(lastClaimedEpoch, 0);

        // unstake normal partial
        vm.prank(alice);
        fjordStaking.unstake(1, 2 ether);

        assertEq(fjordStaking.newStaked(), 3 ether);
        (epoch, staked,) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 3 ether);

        activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 1);

        // unstake normal full
        vm.prank(alice);
        fjordStaking.unstake(1, 3 ether);

        assertEq(fjordStaking.newStaked(), 0 ether);
        (epoch, staked,) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(staked, 0 ether);

        activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 0);

        (totalStaked,,,) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
    }
    /*
    Scenarios: 
    - deposit with both stake and stakeVested same epoch
    - unstake vested instant
    - unstake normal instant
    */

    function test_BothStake_Unstake_Normal_Instant_Vested() public {
        // both stake
        uint256 streamID = createStreamAndStake();
        vm.prank(alice);
        fjordStaking.stake(5 ether);

        // unstake normal partial
        vm.prank(alice);
        fjordStaking.unstake(1, 2 ether);

        assertEq(fjordStaking.newStaked(), 13 ether);
        (uint16 epoch, uint256 staked, uint256 vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 3 ether);
        assertEq(vestedStaked, 10 ether);

        // unstake normal full
        vm.prank(alice);
        fjordStaking.unstake(1, 3 ether);

        assertEq(fjordStaking.newStaked(), 10 ether);
        (epoch, staked,) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 1);
        assertEq(staked, 0 ether);

        // unstake vested
        vm.prank(alice);
        fjordStaking.unstakeVested(streamID);

        assertEq(fjordStaking.newStaked(), 0 ether);

        (uint256 totalStaked,,, uint16 lastClaimedEpoch) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
        assertEq(lastClaimedEpoch, 0);

        (epoch,, vestedStaked) = fjordStaking.deposits(alice, 1);
        assertEq(epoch, 0);
        assertEq(staked, 0 ether);
        assertEq(vestedStaked, 0 ether);

        uint256[] memory activeDeposits = fjordStaking.getActiveDeposits(address(alice));
        assertEq(activeDeposits.length, 0);

        (totalStaked,,,) = fjordStaking.userData(address(alice));
        assertEq(totalStaked, 0 ether);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import "../../src/FjordStaking.sol";
import "./handler/LimitedStakeHandler.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";
import { FjordPointsMock } from "../mocks/FjordPointsMock.sol";

contract InvariantTest is Test {
    FjordStaking private fjordStaking;
    MockERC20 private token;
    LimitedStakeHandler private limitedStakeHandler;
    address private constant SABLIER_ADDRESS = address(0xB10daee1FCF62243aE27776D7a92D39dC8740f95);

    function setUp() public {
        token = new MockERC20("Fjord", "FJO", 18);
        fjordStaking = new FjordStaking(
            address(token),
            address(this),
            SABLIER_ADDRESS,
            address(this),
            address(new FjordPointsMock())
        );
        limitedStakeHandler = new LimitedStakeHandler(fjordStaking, token);
        // Target the StakeHandler contract for fuzzing
        targetContract(address(limitedStakeHandler));
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = limitedStakeHandler.stake.selector;
        selectors[1] = limitedStakeHandler.unstake.selector;
        targetSelector(FuzzSelector({ addr: address(limitedStakeHandler), selectors: selectors }));
    }

    /// @dev Invariant test to ensure the total staked tokens match all users stake
    function invariant_AllSenderTotalStake() public {
        uint256 allSenderTotalStaked = 0;

        // Calculate the total staked amount for all users
        for (uint256 i = 0; i < limitedStakeHandler.getStakersLength(); i++) {
            address sender = limitedStakeHandler.stakers(i);
            if (sender == address(fjordStaking)) {
                continue;
            }
            (uint256 senderTotalStake,, uint16 unredeemedEpoch,) = fjordStaking.userData(sender);
            allSenderTotalStaked += senderTotalStake;
            if (unredeemedEpoch == 0) {
                continue;
            }
            (, uint256 senderStaked,) = fjordStaking.deposits(sender, unredeemedEpoch);
            allSenderTotalStaked += senderStaked;
        }

        // Ensure the sum of all sender staked tokens matches the token balance
        assertEq(
            allSenderTotalStaked,
            token.balanceOf(address(fjordStaking)),
            "Invariant: All sender total staked equal to token balance"
        );
    }
}

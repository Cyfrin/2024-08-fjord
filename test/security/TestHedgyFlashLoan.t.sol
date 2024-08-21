// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import { Test } from "forge-std/Test.sol";
import "forge-std/console2.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract FlashLoanTest is Test {
    function setUp() public { }

    function testLogAllowanceAmountBeforeAllow() public {
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 19687886 });
        MockERC20 usdc = MockERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        uint256 allowedAmount = usdc.allowance(
            0xBc452fdC8F851d7c5B72e1Fe74DFB63bb793D511, 0xC793113F1548B97E37c409f39244EE44241bF2b3
        );
        assertEq(allowedAmount, 0);
    }

    function testLogAllowanceAmountAfterAllow() public {
        vm.createSelectFork({ urlOrAlias: "mainnet", blockNumber: 19687887 });
        MockERC20 usdc = MockERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        uint256 allowedAmount = usdc.allowance(
            0xBc452fdC8F851d7c5B72e1Fe74DFB63bb793D511, 0xC793113F1548B97E37c409f39244EE44241bF2b3
        );
        assertEq(allowedAmount, 1305000000000);
    }
}

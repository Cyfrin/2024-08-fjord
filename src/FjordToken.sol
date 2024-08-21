// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import { ERC20 } from "solmate/tokens/ERC20.sol";

contract FjordToken is ERC20 {
    constructor() ERC20("Fjord Foundry", "FJO", 18) {
        _mint(msg.sender, 100_000_000 ether);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import { ERC20 } from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from
    "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract ERC20BurnableMock is ERC20, ERC20Burnable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) { }
}

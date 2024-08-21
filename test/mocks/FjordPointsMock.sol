// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

import { IFjordPoints } from "src/interfaces/IFjordPoints.sol";

contract FjordPointsMock is IFjordPoints {
    function onStaked(address user, uint256 amount) external pure {
        user;
        amount;
    }

    function onUnstaked(address user, uint256 amount) external pure {
        user;
        amount;
    }
}

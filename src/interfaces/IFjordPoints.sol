// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.21;

interface IFjordPoints {
    function onStaked(address user, uint256 amount) external;
    function onUnstaked(address user, uint256 amount) external;
}

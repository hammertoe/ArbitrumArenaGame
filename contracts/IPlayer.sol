// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GameTypes.sol";

interface IPlayer {
    function reset() external;

    function getAction(
        address[] calldata playerAddrs,
        uint256[] calldata xs,
        uint256[] calldata ys,
        uint256[] calldata healths
    ) external view returns (Action memory);

    function name() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./GameTypes.sol";

interface IPlayer {
    function getAction(GameState calldata state) external returns (Action memory);
    function reset() external;
}

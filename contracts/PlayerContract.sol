// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlayer.sol";
import "./GameTypes.sol";

contract RunAwayPlayer is IPlayer {

    function reset() external override {
        // Reset any internal state variables
        // For example:
        // someStateVariable = 0;
    }

    function getRandomNumber() public view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(
            block.timestamp, 
            block.prevrandao, 
            msg.sender,
            address(this)
        )));
        return randomHash % 9; // Returns a number between 0 and 8 inclusive
    }

    function getAction(GameState calldata state) external override returns (Action memory) {
        Action memory action;
        
        // Move away from the enemy if possible
        action.actionType = ActionType.Move;
        action.direction = Direction(getRandomNumber());
        action.targetPlayer = address(0);
    }
}

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

    function getAction(GameState calldata state) external override returns (Action memory) {
        Action memory action;

        // Find my player state
        PlayerState memory me;
        bool foundMe = false;
        for (uint256 i = 0; i < state.players.length; i++) {
            if (state.players[i].playerAddress == address(this)) {
                me = state.players[i];
                foundMe = true;
                break;
            }
        }

        require(foundMe, "Player not found in game state");

        // Find the closest alive enemy
        PlayerState memory closestEnemy;
        uint256 minDistance = type(uint256).max;
        bool enemyFound = false;

        for (uint256 i = 0; i < state.players.length; i++) {
            PlayerState memory other = state.players[i];

            // Skip if it's me or if the other player is dead
            if (other.playerAddress == address(this) || !other.isAlive) {
                continue;
            }

            uint256 distance = manhattanDistance(me.x, me.y, other.x, other.y);

            if (distance < minDistance) {
                minDistance = distance;
                closestEnemy = other;
                enemyFound = true;
            }
        }

        if (enemyFound) {
            // Determine the direction away from the closest enemy
            Direction escapeDirection = getDirectionAwayFrom(me.x, me.y, closestEnemy.x, closestEnemy.y, state.gridSize);

            // Move away from the enemy if possible
            action.actionType = ActionType.Move;
            action.direction = Direction(escapeDirection);
            action.targetPlayer = address(0);
        } else {
            // No enemies found, stay in place and defend
            action = defaultAction();
        }

        return action;
    }

    // Helper function to calculate Manhattan distance
    function manhattanDistance(uint256 x1, uint256 y1, uint256 x2, uint256 y2) internal pure returns (uint256) {
        uint256 dx = x1 > x2 ? x1 - x2 : x2 - x1;
        uint256 dy = y1 > y2 ? y1 - y2 : y2 - y1;
        return dx + dy;
    }

    // Helper function to determine the direction away from the target
    function getDirectionAwayFrom(
        uint256 fromX,
        uint256 fromY,
        uint256 targetX,
        uint256 targetY,
        uint256 gridSize
    ) internal pure returns (Direction) {
        int256 dx = int256(fromX) - int256(targetX);
        int256 dy = int256(fromY) - int256(targetY);

        // Normalize dx and dy to -1, 0, or 1
        if (dx != 0) {
            dx = dx / abs(dx);
        }
        if (dy != 0) {
            dy = dy / abs(dy);
        }

        // Map (dx, dy) to a direction
        // (dx, dy) combinations are mapped to compass directions
        if (dx == 0 && dy == 1) {
            return Direction.North;
        } else if (dx == 1 && dy == 1) {
            return Direction.Northeast;
        } else if (dx == 1 && dy == 0) {
            return Direction.East;
        } else if (dx == 1 && dy == -1) {
            return Direction.Southeast;
        } else if (dx == 0 && dy == -1) {
            return Direction.South;
        } else if (dx == -1 && dy == -1) {
            return Direction.Southwest;
        } else if (dx == -1 && dy == 0) {
            return Direction.West;
        } else if (dx == -1 && dy == 1) {
            return Direction.Northwest;
        } else {
            return Direction.Stay;
        }
    }

    // Helper function to get absolute value
    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    // Default action (Defend and Stay)
    function defaultAction() internal pure returns (Action memory) {
        return Action({
            actionType: ActionType.Defend,
            direction: Direction(Direction.Stay),
            targetPlayer: address(0)
        });
    }
}

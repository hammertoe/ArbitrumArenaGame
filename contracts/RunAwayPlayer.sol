// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlayer.sol";
import "./GameTypes.sol";

contract RunAwayPlayer is IPlayer {
    string public override name = "RunAwayPlayer";

    struct Player {
        address addr;
        uint256 x;
        uint256 y;
        uint256 health;
    }

    function reset() external override {}

    function getAction(
        address[] calldata playerAddrs,
        uint256[] calldata xs,
        uint256[] calldata ys,
        uint256[] calldata healths
    ) external view override returns (Action memory) {
        Player[] memory players = createPlayerArray(playerAddrs, xs, ys, healths);
        uint256 meIndex = findMyIndex(players);
        return runAwayFromClosestEnemy(players, meIndex);
    }

    function createPlayerArray(
        address[] calldata playerAddrs,
        uint256[] calldata xs,
        uint256[] calldata ys,
        uint256[] calldata healths
    ) internal pure returns (Player[] memory) {
        Player[] memory players = new Player[](playerAddrs.length);
        for (uint256 i = 0; i < playerAddrs.length; i++) {
            players[i] = Player(playerAddrs[i], xs[i], ys[i], healths[i]);
        }
        return players;
    }

    function findMyIndex(Player[] memory players) internal view returns (uint256) {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].addr == address(this)) return i;
        }
        revert("Player not found in game state");
    }

    function runAwayFromClosestEnemy(Player[] memory players, uint256 meIndex) internal pure returns (Action memory) {
        uint256 minDistance = type(uint256).max;
        uint256 enemyIndex = 0;
        bool enemyFound = false;

        for (uint256 i = 0; i < players.length; i++) {
            if (i != meIndex && (players[i].health > 100)) {
                uint256 distance = chebyshevDistance(players[meIndex], players[i]);
                if (distance < minDistance) {
                    minDistance = distance;
                    enemyIndex = i;
                    enemyFound = true;
                }
            }
        }

        if (enemyFound) {
            return createRunAwayAction(players[meIndex], players[enemyIndex]);
        } else {
            return createAction(ActionType.Defend, players[meIndex], players[meIndex], address(0));
        }
    }

    function chebyshevDistance(Player memory p1, Player memory p2) internal pure returns (uint256) {
        uint256 dx = p1.x > p2.x ? p1.x - p2.x : p2.x - p1.x;
        uint256 dy = p1.y > p2.y ? p1.y - p2.y : p2.y - p1.y;
        return dx > dy ? dx : dy;
    }

    function createRunAwayAction(Player memory me, Player memory enemy) internal pure returns (Action memory) {
        Direction runDirection = getOppositeDirection(getDirection(me, enemy));
        return Action({
            actionType: ActionType.Move,
            direction: runDirection,
            targetPlayer: address(0)
        });
    }

    function createAction(
        ActionType actionType,
        Player memory from,
        Player memory to,
        address targetPlayer
    ) internal pure returns (Action memory) {
        return Action({
            actionType: actionType,
            direction: actionType == ActionType.Defend ? Direction.Stay : getDirection(from, to),
            targetPlayer: targetPlayer
        });
    }

    function getDirection(Player memory from, Player memory to) internal pure returns (Direction) {
        int256 dx = int256(to.x) - int256(from.x);
        int256 dy = int256(to.y) - int256(from.y);

        if (dx == 0 && dy > 0) return Direction.North;
        if (dx > 0 && dy > 0) return Direction.Northeast;
        if (dx > 0 && dy == 0) return Direction.East;
        if (dx > 0 && dy < 0) return Direction.Southeast;
        if (dx == 0 && dy < 0) return Direction.South;
        if (dx < 0 && dy < 0) return Direction.Southwest;
        if (dx < 0 && dy == 0) return Direction.West;
        if (dx < 0 && dy > 0) return Direction.Northwest;
        return Direction.Stay;
    }

    function getOppositeDirection(Direction dir) internal pure returns (Direction) {
        if (dir == Direction.North) return Direction.South;
        if (dir == Direction.Northeast) return Direction.Southwest;
        if (dir == Direction.East) return Direction.West;
        if (dir == Direction.Southeast) return Direction.Northwest;
        if (dir == Direction.South) return Direction.North;
        if (dir == Direction.Southwest) return Direction.Northeast;
        if (dir == Direction.West) return Direction.East;
        if (dir == Direction.Northwest) return Direction.Southeast;
        return Direction.Stay;
    }
}
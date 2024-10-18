// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum ActionType { Move, Attack, Defend }

enum Direction {
    Stay,    // 0
    North,   // 1
    Northeast, // 2
    East,    // 3
    Southeast, // 4
    South,   // 5
    Southwest, // 6
    West,    // 7
    Northwest // 8
}

struct Action {
    ActionType actionType;
    Direction direction;
    address targetPlayer; // Used only for Attack actions
}

struct PlayerState {
    address playerAddress;
    uint256 x;
    uint256 y;
    uint256 health;
    bool isAlive;
    uint256 defenseBuff;
    string name;
}

struct GameState {
    uint256 gridSize;
    PlayerState[] players;
}

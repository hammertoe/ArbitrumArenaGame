// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library PlayerFlagStructs {
    struct Player {
        address playerAddress;
        uint16 x;
        uint16 y;
        uint32 score;
        bool captured;
    }

    struct Flag {
        uint16 x;
        uint16 y;
        bool captured;
    }
}

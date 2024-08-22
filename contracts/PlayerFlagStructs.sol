// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

library PlayerFlagStructs {
    struct Player {
        address playerAddress;
        uint x;
        uint y;
        uint score;
    }

    struct Flag {
        uint x;
        uint y;
        bool captured;
    }
}

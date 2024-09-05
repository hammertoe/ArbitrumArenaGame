// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./PlayerFlagStructs.sol";

contract CaptureTheFlag {
    using PlayerFlagStructs for PlayerFlagStructs.Player;
    using PlayerFlagStructs for PlayerFlagStructs.Flag;

    PlayerFlagStructs.Player[] public players;
    PlayerFlagStructs.Flag[] public flags;
    uint public gridSize;


    event MoveCalculated(address player, uint direction);

    function registerPlayer(address playerAddress) public {
        // Check if the player is already registered
        for (uint i = 0; i < players.length; i++) {
            if (players[i].playerAddress == playerAddress) {
                // Player is already registered, skip
                return;
            }
        }
    
        // If not registered, add the player to the array
        players.push(PlayerFlagStructs.Player(playerAddress, 0, 0, 0));    
    }

    function registerMultiplePlayers(address[] memory playerAddresses) public {
        for (uint i = 0; i < playerAddresses.length; i++) {
            registerPlayer(playerAddresses[i]);
        }
    }

    function getNumPlayers() public view returns (uint256) {
        return players.length;
    }

    function addFlag(uint x, uint y) public {
        flags.push(PlayerFlagStructs.Flag(x, y, false));
    }

    function gameState() public view returns (PlayerFlagStructs.Player[] memory, PlayerFlagStructs.Flag[] memory) {
        return (players, flags);
    }

    function startGame(uint _gridSize) public {
        distributePlayersRandomly(_gridSize);
    }

    function distributePlayersRandomly(uint256 Y) public {
        uint256 X = players.length;

        require(X <= Y * Y, "Not enough space on the board for all players");

        // Create an array to track used positions
        bool[][] memory usedPositions = new bool[][](Y);
        for (uint i = 0; i < Y; i++) {
            usedPositions[i] = new bool[](Y);
        }

        for (uint256 i = 0; i < X; i++) {
            uint256 x;
            uint256 y;

            // Generate random positions until an unused one is found
            do {
                x = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i))) % Y;
                y = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, i, x))) % Y;
            } while (usedPositions[x][y]);

            // Mark the position as used
            usedPositions[x][y] = true;

            // Assign the position to the player
            players[i].x = x;
            players[i].y = y;
        }
    }

    function iteratePlayers() public {
        for (uint i = 0; i < players.length; i++) {
            PlayerFlagStructs.Player storage player = players[i];
            PlayerContract playerContract = PlayerContract(player.playerAddress);
            uint direction = playerContract.calcMove(player, players, flags);
            emit MoveCalculated(player.playerAddress, direction);

            // Update player position accordingly
            if (direction == 1) { // North
                if (player.y > 0) player.y -= 1;
            } else if (direction == 2) { // North East
                if (player.y > 0) player.y -= 1;
                if (player.x < gridSize) player.x += 1;
            } else if (direction == 3) { // East
                if (player.x < gridSize) player.x += 1;
            } else if (direction == 4) { // South East
                if (player.y < gridSize) player.y += 1;
                if (player.x < gridSize) player.x += 1;
            } else if (direction == 5) { // South
                if (player.y < gridSize) player.y += 1;
            } else if (direction == 6) { // South West
                if (player.y < gridSize) player.y += 1;
                if (player.x > 0) player.x -= 1;
            } else if (direction == 7) { // West
                if (player.x > 0) player.x -= 1;
            } else if (direction == 8) { // North West
                if (player.y > 0) player.y -= 1;
                if (player.x > 0) player.x -= 1;
            }
        }
    }

}

abstract contract PlayerContract {
    function calcMove(PlayerFlagStructs.Player memory player, PlayerFlagStructs.Player[] memory players, PlayerFlagStructs.Flag[] memory flags) public virtual returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "./PlayerFlagStructs.sol";

contract CaptureTheFlag {
    using PlayerFlagStructs for PlayerFlagStructs.Player;
    using PlayerFlagStructs for PlayerFlagStructs.Flag;

    PlayerFlagStructs.Player[] public players;
    PlayerFlagStructs.Flag[] public flags;

    event MoveCalculated(address player, uint direction);

    function registerPlayer(address playerAddress) public {
        players.push(PlayerFlagStructs.Player(playerAddress, 0, 0, 0));
    }

    function addFlag(uint x, uint y) public {
        flags.push(PlayerFlagStructs.Flag(x, y, false));
    }

    function gameState() public view returns (PlayerFlagStructs.Player[] memory, PlayerFlagStructs.Flag[] memory) {
        return (players, flags);
    }

    function iteratePlayers() public {
        uint gridSize = 4;
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

            // Check if player is at the location of a flag
            for (uint j = 0; j < flags.length; j++) {
                if (!flags[j].captured && player.x == flags[j].x && player.y == flags[j].y) {
                    player.score += 1;
                    flags[j].captured = true;
                }
            }

            // Check if player is at the same location as another player
            for (uint k = 0; k < players.length; k++) {
                if (i != k) {
                    PlayerFlagStructs.Player storage otherPlayer = players[k];
                    // We are no same square as another player
                    if (player.x == otherPlayer.x && player.y == otherPlayer.y) {
                        // This player is stronger than other player and hence beats it
                        if (player.score > otherPlayer.score) {
                            player.score += otherPlayer.score;
                            otherPlayer.score = 0;
                        }

                        // Other player was stronger, we lose!
                        if (player.score < otherPlayer.score) {
                            otherPlayer.score += player.score;
                            player.score = 0;
                        }
                    }
                }
            } 
        }
    }

}

abstract contract PlayerContract {
    function calcMove(PlayerFlagStructs.Player memory player, PlayerFlagStructs.Player[] memory players, PlayerFlagStructs.Flag[] memory flags) public virtual returns (uint);
}

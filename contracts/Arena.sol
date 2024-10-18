// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPlayer.sol";
import "./GameTypes.sol";

contract Arena {
    // State variables
    uint256 public gridSize = 10;
    bool public gameStarted = false;
    uint256 public totalTurns = 0;
    uint256 public maxTurns = 100;

    mapping(address => PlayerInfo) public players;
    address[] public playerAddresses;

    // Mapping to track occupied locations
    mapping(uint256 => bool) private occupiedPositions;

    // Internal PlayerInfo struct (used for internal logic)
    struct PlayerInfo {
        address playerAddress;
        uint256 x;
        uint256 y;
        uint256 health;
        uint256 defenseBuff;
        string name;
    }

    // Events
    event PlayerRegistered(address playerAddress, string name);
    event GameStarted();
    event TurnPlayed(
            uint256 turnNumber, 
            address[] playerAddrs,
            uint256[] xs,
            uint256[] ys,
            uint256[] healths);
    event GameEnded(address winner);
    event ActionFailed(address playerAddress);
    event ActionSuccess(address playerAddress);


    // Modifiers
    modifier onlyBeforeGameStart() {
        require(!gameStarted, "Game has already started");
        _;
    }

    modifier onlyDuringGame() {
        require(gameStarted, "Game has not started yet");
        _;
    }

    // Register a new player
    function registerPlayer(address playerContract) public onlyBeforeGameStart {
        require(playerContract != address(0), "Invalid player contract address");
        require(players[playerContract].playerAddress == address(0), "Player already registered");

        // Fetch the player's name
        string memory playerName = IPlayer(playerContract).name();

        // Initialize the player at a random position
        PlayerInfo memory newPlayer = PlayerInfo({
            playerAddress: playerContract,
            x: 0,
            y: 0,
            health: 100,
            defenseBuff: 0,
            name: playerName
        });

        players[playerContract] = newPlayer;
        playerAddresses.push(playerContract);

        emit PlayerRegistered(playerContract, playerName);
    }

    function registerMultiplePlayers(address[] memory playerContracts) public {
        for (uint i = 0; i < playerContracts.length; i++) {
            registerPlayer(playerContracts[i]);
        }
    }

    function getNumPlayers() public view returns (uint256) {
        return playerAddresses.length;
    }

    // Start the game
    function startGame() public {

        require(playerAddresses.length >= 2, "At least two players are required to start the game");

        // Reset the game state
        resetGame();

        gameStarted = true;
        emit GameStarted();
        (
            address[] memory playerAddrs,
            uint256[] memory xs,
            uint256[] memory ys,
            uint256[] memory healths
        ) = getGameState();
        emit TurnPlayed(totalTurns, playerAddrs, xs, ys, healths);    
    }

    // Reset the game state without clearing registered players
    function resetGame() internal {
        // Reset game state variables
        gameStarted = false;
        totalTurns = 0;


         // Clear the occupied positions mapping
        for (uint256 i = 0; i < gridSize * gridSize; i++) {
            occupiedPositions[i] = false;
        }

        // Reset each player's state and call reset on player contracts
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddr = playerAddresses[i];
            PlayerInfo storage player = players[playerAddr];

            // Variable to help with reseeding randomness during retries
            uint256 attempt = 0;
            uint256 index;

            // Find a random unoccupied position for the player
            do {
                index = uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.prevrandao,
                            playerAddr,
                            totalTurns,
                            attempt // Incremented on each retry to change randomness
                        )
                    )
                ) % (gridSize * gridSize);
                attempt++;
            } while (occupiedPositions[index]);

            // Mark the position as occupied
            occupiedPositions[index] = true;

            // Calculate x and y from the index
            player.x = index % gridSize;
            player.y = index / gridSize;
            player.health = 100;
            player.defenseBuff = 0;

            // Call reset on the player contract
            IPlayer(playerAddr).reset();
        }
    }

    // Reset the game state without clearing registered players
    function XresetGame() internal {
        // Reset game state variables
        gameStarted = false;
        totalTurns = 0;

        // Reset each player's state and call reset on player contracts
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddr = playerAddresses[i];
            PlayerInfo storage player = players[playerAddr];

            // Re-initialize the player at a random position
            uint256 index = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, playerAddr, totalTurns))) % (gridSize * gridSize);
            player.x = index % gridSize;
            player.y = index / gridSize;
            player.health = 100;
            player.defenseBuff = 0;

            // Call reset on the player contract
            IPlayer(playerAddr).reset();
        }
    }

    function playTurn() public onlyDuringGame {
        totalTurns++;
        Action[] memory actions = new Action[](playerAddresses.length);

        uint256 gasLimitPerPlayer = 200000; // Adjust as needed

        // Declare memory arrays for tracking player actions
        bool[] memory playerMoved = new bool[](playerAddresses.length);
        bool[] memory playerAttacked = new bool[](playerAddresses.length);

        // Prepare game state data to pass to players
        (
            address[] memory playerAddrs,
            uint256[] memory xs,
            uint256[] memory ys,
            uint256[] memory healths
        ) = getGameState();

        // Collect actions from each player
        for (uint256 i = 0; i < playerAddrs.length; i++) {
            address playerAddr = playerAddrs[i];

            if (healths[i] > 0) {
                try IPlayer(playerAddr).getAction{gas: gasLimitPerPlayer}(
                    playerAddrs,
                    xs,
                    ys,
                    healths
                ) returns (Action memory action) {
                    emit ActionSuccess(playerAddr);
                    // Validate the action
                    actions[i] = validateAction(action);
                } catch {
                    // Assign default action if getAction fails
                    actions[i] = defaultAction();
                    emit ActionFailed(playerAddr);
                }
            } else {
                // Dead players do nothing
                actions[i] = defaultAction();
            }
        }

        // Resolve actions, passing the tracking arrays
        resolveActions(actions, playerMoved, playerAttacked);

        // Process health regeneration
        processHealthRegeneration(playerMoved, playerAttacked);

        (
            playerAddrs,
            xs,
            ys,
            healths
        ) = getGameState();
        emit TurnPlayed(totalTurns, playerAddrs, xs, ys, healths);

        // Check for end game conditions
        if (checkGameOver()) {
            gameStarted = false;
            address winner = getWinner();
            emit GameEnded(winner);
        } else if (totalTurns >= maxTurns) {
            gameStarted = false;
            address winner = getWinnerByHealth();
            emit GameEnded(winner);
        }
    }

    function defaultAction() internal pure returns (Action memory) {
        return Action({
            actionType: ActionType.Defend,
            direction: Direction.Stay,
            targetPlayer: address(0)
        });
    }

    function validateAction(Action memory action) internal pure returns (Action memory) {
        // Validate action type
        if (uint8(action.actionType) > uint8(ActionType.Defend)) {
            return defaultAction(); // Invalid action type, return default action
        }

        // Validate direction
        if (uint8(action.direction) > uint8(Direction.Northwest)) {
            return defaultAction(); // Invalid direction, return default action
        }

        return action; // Action is valid
    }

    // Resolve actions
    function resolveActions(
        Action[] memory actions,
        bool[] memory playerMoved,
        bool[] memory playerAttacked
    ) internal {
        // Reset defense buffs
        resetDefenseBuffs();

        // First, process moves and defenses
        for (uint256 i = 0; i < actions.length; i++) {
            address playerAddr = playerAddresses[i];
            PlayerInfo storage player = players[playerAddr];
            Action memory action = actions[i];

            if (!(player.health > 0)) continue;

            if (action.actionType == ActionType.Move) {
                // Calculate new position based on direction
                (uint256 newX, uint256 newY) = getNewPosition(player.x, player.y, action.direction);

                // Move the player if the position is valid and not occupied
                if (isValidPosition(newX, newY) && !isPositionOccupied(newX, newY, playerAddr)) {
                    player.x = newX;
                    player.y = newY;
                    playerMoved[i] = true; // Mark that the player moved
                }
            } else if (action.actionType == ActionType.Defend) {
                // Apply defense buff
                player.defenseBuff = 50; // Reduces incoming damage by 50%
            }
            // Attacks are processed in the next loop
        }

        // Then, process attacks
        for (uint256 i = 0; i < actions.length; i++) {
            address attackerAddr = playerAddresses[i];
            PlayerInfo storage attacker = players[attackerAddr];
            Action memory action = actions[i];

            if (!(attacker.health > 0)) continue;

            if (action.actionType == ActionType.Attack) {
                // Calculate attack position based on direction
                (uint256 targetX, uint256 targetY) = getNewPosition(attacker.x, attacker.y, action.direction);

                // Find if any player is at the target position
                (address targetPlayerAddr, uint256 targetIndex) = getPlayerAtPosition(targetX, targetY);
                if (targetPlayerAddr != address(0)) {
                    PlayerInfo storage targetPlayer = players[targetPlayerAddr];

                    // Determine attack success based on attacker's health
                    uint256 successChance = attacker.health > 80 ? 90 : 50;
                    uint256 rand = random(uint256(keccak256(abi.encodePacked(attackerAddr, targetPlayerAddr, totalTurns)))) % 100;

                    if (rand < successChance) {
                        uint256 damage = 20;

                        // Apply target's defense buff
                        if (targetPlayer.defenseBuff > 0) {
                            damage = (damage * (100 - targetPlayer.defenseBuff)) / 100;
                        }

                        // Apply damage
                        if (targetPlayer.health <= damage) {
                            targetPlayer.health = 0;
                        } else {
                            targetPlayer.health -= damage;
                        }
                    }
                    // Mark that the target player was attacked
                    playerAttacked[targetIndex] = true;
                }
            }
        }
    }

    // Process health regeneration
    function processHealthRegeneration(
        bool[] memory playerMoved,
        bool[] memory playerAttacked
    ) internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddr = playerAddresses[i];
            PlayerInfo storage player = players[playerAddr];

            if (!(player.health > 0)) continue;

            // If the player did not move and was not attacked
            if (!playerMoved[i] && !playerAttacked[i]) {
                player.health += 5;
                if (player.health > 100) {
                    player.health = 100; // Cap health at 100
                }
            }
        }
    }

    // Reset defense buffs for all players
    function resetDefenseBuffs() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            players[playerAddresses[i]].defenseBuff = 0;
        }
    }

    // Calculate new position based on direction
    function getNewPosition(uint256 x, uint256 y, Direction direction) internal pure returns (uint256, uint256) {
        int256 newX = int256(x);
        int256 newY = int256(y);

        if (direction == Direction.North) {
            newY += 1;
        } else if (direction == Direction.Northeast) {
            newX += 1;
            newY += 1;
        } else if (direction == Direction.East) {
            newX += 1;
        } else if (direction == Direction.Southeast) {
            newX += 1;
            newY -= 1;
        } else if (direction == Direction.South) {
            newY -= 1;
        } else if (direction == Direction.Southwest) {
            newX -= 1;
            newY -= 1;
        } else if (direction == Direction.West) {
            newX -= 1;
        } else if (direction == Direction.Northwest) {
            newX -= 1;
            newY += 1;
        }
        // Direction.Stay does not change position

        // Ensure new positions are non-negative
        return (uint256(newX), uint256(newY));
    }

    // Check if a position is within the grid boundaries
    function isValidPosition(uint256 x, uint256 y) internal view returns (bool) {
        return x < gridSize && y < gridSize;
    }

    // Check if a position is occupied by another player
    function isPositionOccupied(uint256 x, uint256 y, address excludePlayer) internal view returns (bool) {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddr = playerAddresses[i];
            if (playerAddr == excludePlayer) continue;
            PlayerInfo storage player = players[playerAddr];
            if (player.health > 0 && player.x == x && player.y == y) {
                return true;
            }
        }
        return false;
    }

    // Get the address and index of the player at a specific position
    function getPlayerAtPosition(uint256 x, uint256 y) internal view returns (address, uint256) {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            PlayerInfo storage player = players[playerAddresses[i]];
            if (player.health > 0 && player.x == x && player.y == y) {
                return (player.playerAddress, i);
            }
        }
        return (address(0), 0);
    }

    // Check if the game is over (only one or zero players alive)
    function checkGameOver() internal view returns (bool) {
        uint256 aliveCount = 0;

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            if (players[playerAddresses[i]].health > 0) {
                aliveCount++;
                if (aliveCount > 1) {
                    return false;
                }
            }
        }
        return true;
    }

    // Get the winner (the last player alive)
    function getWinner() internal view returns (address) {
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            address playerAddr = playerAddresses[i];
            if (players[playerAddr].health > 0) {
                return playerAddr;
            }
        }
        return address(0); // No winner (tie)
    }

    // Get the winner by highest health if max turns reached
    function getWinnerByHealth() internal view returns (address) {
        address winner = address(0);
        uint256 highestHealth = 0;

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            PlayerInfo storage player = players[playerAddresses[i]];
            if (player.health > 0 && player.health > highestHealth) {
                highestHealth = player.health;
                winner = player.playerAddress;
            }
        }
        return winner;
    }

    function getGameState()
        public
        view
        returns (
            address[] memory playerAddrs,
            uint256[] memory xs,
            uint256[] memory ys,
            uint256[] memory healths
        )
    {
        uint256 numPlayers = playerAddresses.length;

        // Initialize return variables
        playerAddrs = new address[](numPlayers);
        xs = new uint256[](numPlayers);
        ys = new uint256[](numPlayers);
        healths = new uint256[](numPlayers);

        for (uint256 i = 0; i < numPlayers; i++) {
            address playerAddr = playerAddresses[i];
            PlayerInfo storage player = players[playerAddr];
            playerAddrs[i] = playerAddr;
            xs[i] = player.x;
            ys[i] = player.y;
            healths[i] = player.health;
        }

        return (playerAddrs, xs, ys, healths);
    }

    // Generate a pseudo-random number
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, seed)));
    }
}

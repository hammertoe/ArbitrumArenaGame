const hre = require("hardhat");
require('dotenv').config();

const GAME_TURNS = 10;

async function main() {
    // Get the Arena contract address from the environment variable
    const arenaAddress = process.env.CAPTURE_THE_FLAG_CONTRACT_ADDRESS;
    if (!arenaAddress || !hre.ethers.isAddress(arenaAddress)) {
        console.error("Invalid or missing CAPTURE_THE_FLAG_CONTRACT_ADDRESS environment variable.");
        process.exit(1);
    }
    // Attach to the Arena contract
    const Arena = await hre.ethers.getContractFactory("Arena");
    const arena = await Arena.attach(arenaAddress);

    // Get the number of registered players
    const numPlayersBN = await arena.getNumPlayers();
    const numPlayers = Number(numPlayersBN);

    for (let turn = 0; turn < GAME_TURNS; turn++) {
        console.log(`Game turn ${turn + 1}`);

        // Play a turn
        try {
            const tx = await arena.playTurn();
            await tx.wait();
        } catch (error) {
            console.error(`Error during playTurn at turn ${turn + 1}:`, error.message);
            if (error.reason) {
                console.error('Revert reason:', error.reason);
            }
            // Exit the loop if the game has ended
            break;
        }

        // Fetch player addresses in parallel
        const playerAddressPromises = [];
        for (let i = 0; i < numPlayers; i++) {
            playerAddressPromises.push(arena.playerAddresses(i));
        }
        const playerAddresses = await Promise.all(playerAddressPromises);

        // Fetch player info in parallel
        const playerInfoPromises = playerAddresses.map((playerAddress) => arena.players(playerAddress));
        const playerInfos = await Promise.all(playerInfoPromises);

        // Print out the location and status of each player
        for (let i = 0; i < numPlayers; i++) {
            const playerAddress = playerAddresses[i];
            const player = playerInfos[i];

            // Access player's properties
            const x = player.x.toString();
            const y = player.y.toString();
            const health = player.health.toString();
            const isAlive = player.isAlive;

            console.log(`Player ${i + 1} (${playerAddress}) location: x=${x}, y=${y}, health=${health}, alive=${isAlive}`);
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Script failed with error:", error);
        process.exit(1);
    });

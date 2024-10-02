const hre = require("hardhat");
require('dotenv').config();

async function main() {
    // Constants
    const UNIT_FACTOR = 10;       // Specify the unit factor for grid size calculation

     // Get the Arena contract address from the environment variable
    const arenaAddress = process.env.CAPTURE_THE_FLAG_CONTRACT_ADDRESS;
    if (!arenaAddress || !hre.ethers.isAddress(arenaAddress)) {
        console.error("Invalid or missing CAPTURE_THE_FLAG_CONTRACT_ADDRESS environment variable.");
        process.exit(1);
    }
    // Attach to the Arena contract
    const Arena = await hre.ethers.getContractFactory("Arena");
    const arena = await Arena.attach(arenaAddress);
    const numPlayers = Number(await arena.getNumPlayers());

    // Calculate the grid size
    const totalSpace = numPlayers * UNIT_FACTOR;
    const gridSize = Math.ceil(Math.sqrt(totalSpace));

    try {
        const tx = await arena.startGame();
        await tx.wait(); // Wait for the transaction to be mined
        console.log("Game started successfully");
    } catch (error) {
        if (error.message) {
            console.error("Error calling startGame:", error.message);
        } else {
            console.error("Error calling startGame:", error);
        }
    }
    // Print out the location of each player
    for (let i = 0; i < numPlayers; i++) {
        // Get the player's address from the playerAddresses array
        const playerAddress = await arena.playerAddresses(i);
        // Get the player's info from the players mapping
        const player = await arena.players(playerAddress);

        // Access the player's x and y positions
        const x = player.x.toString(); // Convert BigNumber to string
        const y = player.y.toString();

        console.log(`Player ${i + 1} (${playerAddress}) location: x=${x}, y=${y}`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("Script failed with error:", error);
        process.exit(1);
    });

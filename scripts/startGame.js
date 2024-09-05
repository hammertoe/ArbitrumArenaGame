const hre = require("hardhat");
require('dotenv').config();

async function main() {
    // Constants
    const UNIT_FACTOR = 10;       // Specify the unit factor for grid size calculation

     // Get the CaptureTheFlag contract address from the environment variable
    const captureTheFlagAddress = process.env.CAPTURE_THE_FLAG_CONTRACT_ADDRESS;
    if (!captureTheFlagAddress || !hre.ethers.isAddress(captureTheFlagAddress)) {
        console.error("Invalid or missing CAPTURE_THE_FLAG_CONTRACT_ADDRESS environment variable.");
        process.exit(1);
    }
    // Attach to the CaptureTheFlag contract
    const CaptureTheFlag = await hre.ethers.getContractFactory("CaptureTheFlag");
    const captureTheFlag = await CaptureTheFlag.attach(captureTheFlagAddress);
    const numPlayers = Number(await captureTheFlag.getNumPlayers());

    // Calculate the grid size
    const totalSpace = numPlayers * UNIT_FACTOR;
    const gridSize = Math.ceil(Math.sqrt(totalSpace));

    // Start the game with the calculated grid size
    const startGameTx = await captureTheFlag.startGame(UNIT_FACTOR);
    await startGameTx.wait();  // Wait for the transaction to be mined

    console.log(`Game started with grid size: ${gridSize}`);

     // Print out the location of each player
     for (let i = 0; i < numPlayers; i++) {
        const player = await captureTheFlag.players(i);
        console.log(`Player ${i + 1} location: x=${player.x}, y=${player.y}`);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

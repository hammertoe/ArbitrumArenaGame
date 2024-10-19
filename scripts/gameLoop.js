const { ethers } = require("hardhat");
require('dotenv').config();

async function main() {
    const arenaAddress = process.env.ARENA_CONTRACT_ADDRESS;

    if (!arenaAddress || !hre.ethers.isAddress(arenaAddress)) {
        console.error("Invalid or missing ARENA_CONTRACT_ADDRESS environment variable.");
        process.exit(1);
    }

    const provider = ethers.provider;
    const [signer] = await ethers.getSigners();
    const arenaAbi = require('../artifacts/contracts/Arena.sol/Arena.json').abi; // Load the ABI
    const arenaContract = new ethers.Contract(arenaAddress, arenaAbi, signer);

    console.log('Connected to contract at:', arenaAddress);

    // Start the game and enter the game loop
    try {
        // run gameloop in a loop indefinitely
        while (true) {
            await gameLoop(arenaContract);
        }
    } catch (error) {
        console.error('Error running game loop', error);
    }
}

async function gameLoop(arenaContract) {
    let gameStarted = await arenaContract.gameStarted();
    if (!gameStarted) {
        console.log('Waiting for game to start...');
        await new Promise((resolve) => {
            const interval = setInterval(async () => {
                gameStarted = await arenaContract.gameStarted();
                if (gameStarted) {
                    clearInterval(interval);
                    resolve();
                }
            }, 5000);
        });
    }

    console.log("Game has started!");

    const gridSize = Number(await arenaContract.gridSize());
    const maxTurns = 100;

    for (let turn = 0; turn < maxTurns;) {
        console.log(`Playing turn ${turn + 1}`);
        try {
            const tx = await arenaContract.playTurn();
            await tx.wait();
            console.log(`Turn ${turn + 1} executed.`);
            turn++;
        } catch (error) {
            console.error(`Error during playTurn at turn ${turn + 1}:`, error);
        }

        gameStarted = await arenaContract.gameStarted();
        if (!gameStarted) {
            console.log('Game has ended!');
            break;
        }
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });


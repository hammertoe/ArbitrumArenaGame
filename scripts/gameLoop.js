const { ethers } = require("hardhat");

async function main() {
    const arenaAddress = '0xCd82cE99045CaC23481677749F88AEd5ef35c1Fe';

    const provider = ethers.provider;
    const [signer] = await ethers.getSigners();
    const arenaAbi = require('../artifacts/contracts/Arena.sol/Arena.json').abi; // Load the ABI
    const arenaContract = new ethers.Contract(arenaAddress, arenaAbi, signer);

    console.log('Connected to contract at:', arenaAddress);

    // Start the game and enter the game loop
    try {
        //const tx = await arenaContract.startGame();
        //await tx.wait();
        //console.log('Game started!');
        await gameLoop(arenaContract);
    } catch (error) {
        console.error('Error starting game:', error);
    }
}

async function gameLoop(arenaContract) {
    let gameStarted = await arenaContract.gameStarted();
    if (!gameStarted) {
        console.log('Game has not started yet.');
        return;
    }

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

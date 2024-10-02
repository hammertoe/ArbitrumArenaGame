const hre = require("hardhat");
require('dotenv').config();

async function main() {
    // Get the Arena contract address from the environment variable
    const arenaAddress = process.env.CAPTURE_THE_FLAG_CONTRACT_ADDRESS;
    if (!arenaAddress || !hre.ethers.isAddress(arenaAddress)) {
        console.error("Invalid or missing CAPTURE_THE_FLAG_CONTRACT_ADDRESS environment variable.");
        process.exit(1);
    }

    // Get player addresses from the environment variable
    const playerAddresses = process.env.PLAYER_ADDRESSES ? process.env.PLAYER_ADDRESSES.split(',') : [];

    // Ensure all provided addresses are valid
    for (const address of playerAddresses) {
        if (!hre.ethers.isAddress(address)) {
            console.error(`Invalid address: ${address}`);
            process.exit(1);
        }
    }

    if (playerAddresses.length === 0) {
        console.error("Please provide at least one player contract address in PLAYER_ADDRESSES.");
        process.exit(1);
    }

    // Attach to the Arena contract
    const Arena = await hre.ethers.getContractFactory("Arena");
    const arena = await Arena.attach(arenaAddress);

    // Register the provided player contract addresses
    const tx = await arena.registerMultiplePlayers(playerAddresses);
    await tx.wait(); // Wait for the transaction to be mined

    console.log("All player contracts registered with Arena");
    console.log(await arena.getNumPlayers());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

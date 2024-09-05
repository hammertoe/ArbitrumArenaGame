const hre = require("hardhat");
require('dotenv').config();

async function main() {
    // Get the CaptureTheFlag contract address from the environment variable
    const captureTheFlagAddress = process.env.CAPTURE_THE_FLAG_CONTRACT_ADDRESS;
    if (!captureTheFlagAddress || !hre.ethers.isAddress(captureTheFlagAddress)) {
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

    // Attach to the CaptureTheFlag contract
    const CaptureTheFlag = await hre.ethers.getContractFactory("CaptureTheFlag");
    const captureTheFlag = await CaptureTheFlag.attach(captureTheFlagAddress);

    // Register the provided player contract addresses
    const tx = await captureTheFlag.registerMultiplePlayers(playerAddresses);
    await tx.wait(); // Wait for the transaction to be mined

    console.log("All player contracts registered with CaptureTheFlag");
    console.log(await captureTheFlag.getNumPlayers());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

async function main() {
    // Constants
    const NUMBER_OF_PLAYERS = 5;  // Specify the number of player contracts to create

    // Compile contracts
    await hre.run('compile');
    
    // Deploy the CaptureTheFlag contract
    const CaptureTheFlag = await hre.ethers.getContractFactory("CaptureTheFlag");
    const captureTheFlag = await CaptureTheFlag.deploy();
    await captureTheFlag.waitForDeployment();
    
    console.log("CaptureTheFlag deployed to:", await captureTheFlag.getAddress());

    // Array to keep track of player contract addresses
    const playerContracts = [];

    // Deploy MyPlayerContract instances in a loop and register them with CaptureTheFlag
    const MyPlayerContract = await hre.ethers.getContractFactory("MyPlayerContract");
    
    for (let i = 0; i < NUMBER_OF_PLAYERS; i++) {
        const myPlayerContract = await MyPlayerContract.deploy();
        await myPlayerContract.waitForDeployment();
        
        const playerAddress = await myPlayerContract.getAddress();
        console.log(`MyPlayerContract ${i + 1} deployed to:`, playerAddress);

        // Register the player contract with the CaptureTheFlag contract
        const tx = await captureTheFlag.registerPlayer(playerAddress);
        await tx.wait();  // Wait for the transaction to be mined
        
        console.log(`MyPlayerContract ${i + 1} registered with CaptureTheFlag`);

        // Add the player contract to the array
        playerContracts.push(playerAddress);
    }

    console.log("All player contracts deployed and registered:");
    console.log(playerContracts);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

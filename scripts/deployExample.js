async function main() {
    // Constants
    const NUMBER_OF_PLAYERS = 5;  // Specify the number of player contracts to create
    const UNIT_FACTOR = 10;       // Specify the unit factor for grid size calculation

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

    // Calculate the grid size
    const totalSpace = NUMBER_OF_PLAYERS * UNIT_FACTOR;
    const gridSize = Math.ceil(Math.sqrt(totalSpace));

    // Start the game with the calculated grid size
    const startGameTx = await captureTheFlag.startGame(UNIT_FACTOR);
    await startGameTx.wait();  // Wait for the transaction to be mined

    console.log(`Game started with grid size: ${gridSize}`);

     // Print out the location of each player
     for (let i = 0; i < NUMBER_OF_PLAYERS; i++) {
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

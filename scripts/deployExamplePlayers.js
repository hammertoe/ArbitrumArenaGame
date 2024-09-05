async function main() {
    // Constants
    const NUMBER_OF_PLAYERS = 5;  // Specify the number of player contracts to create
    const UNIT_FACTOR = 10;       // Specify the unit factor for grid size calculation

    // Compile contracts
    await hre.run('compile');
    
    // Array to keep track of player contract addresses
    const playerContracts = [];

    // Deploy MyPlayerContract instances in a loop and register them with CaptureTheFlag
    const MyPlayerContract = await hre.ethers.getContractFactory("MyPlayerContract");
    
    for (let i = 0; i < NUMBER_OF_PLAYERS; i++) {
        const myPlayerContract = await MyPlayerContract.deploy();
        await myPlayerContract.waitForDeployment();
        
        const playerAddress = await myPlayerContract.getAddress();
        console.log(`MyPlayerContract ${i + 1} deployed to:`, playerAddress);
    }

    console.log("Sample player contracts deployed:");
    console.log(playerContracts);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

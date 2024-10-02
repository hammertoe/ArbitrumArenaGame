async function main() {
    // Compile contracts
    await hre.run('compile');
    
    // Deploy the Arena contract
    const Arena = await hre.ethers.getContractFactory("Arena");
    const arena = await Arena.deploy();
    await arena.waitForDeployment();
    
    console.log("Arena deployed to:", await arena.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

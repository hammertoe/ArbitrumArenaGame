async function main() {
    // Compile contracts
    await hre.run('compile');
    
    // Deploy the CaptureTheFlag contract
    const CaptureTheFlag = await hre.ethers.getContractFactory("CaptureTheFlag");
    const captureTheFlag = await CaptureTheFlag.deploy();
    await captureTheFlag.waitForDeployment();
    
    console.log("CaptureTheFlag deployed to:", await captureTheFlag.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

async function main() {
    // Compile contracts
    await hre.run('compile');
    
    // Deploy the CaptureTheFlag contract
    const CaptureTheFlag = await hre.ethers.getContractFactory("CaptureTheFlag");
    const captureTheFlag = await CaptureTheFlag.deploy();
    await captureTheFlag.waitForDeployment();
    
    console.log("CaptureTheFlag deployed to:", await captureTheFlag.getAddress());

    // Deploy MyPlayerContract (which implements PlayerContract)
    const MyPlayerContract = await hre.ethers.getContractFactory("MyPlayerContract");
    const myPlayerContract = await MyPlayerContract.deploy();
    await myPlayerContract.waitForDeployment();
    
    console.log("MyPlayerContract deployed to:", await myPlayerContract.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
	console.error(error);
	process.exit(1);
    });

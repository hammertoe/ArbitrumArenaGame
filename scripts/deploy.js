async function main() {
  // Compile contracts
  await hre.run('compile');

  // Deploy the CaptureTheFlag contract
  const CaptureTheFlag = await hre.ethers.getContractFactory("CaptureTheFlag");
  const captureTheFlag = await CaptureTheFlag.deploy();
  await captureTheFlag.deployed();

  console.log("CaptureTheFlag deployed to:", captureTheFlag.address);

  // Deploy MyPlayerContract (which implements PlayerContract)
  const MyPlayerContract = await hre.ethers.getContractFactory("MyPlayerContract");
  const myPlayerContract = await MyPlayerContract.deploy();
  await myPlayerContract.deployed();

  console.log("MyPlayerContract deployed to:", myPlayerContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

require("@nomicfoundation/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.21",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    arbitrumSepolia: {
//	url: "https://arbitrum-sepolia.blockpi.network/v1/rpc/public",
	url: "https://sepolia-rollup.arbitrum.io/rpc",
	accounts: [`0x${process.env.PRIVATE_KEY}`], // Replace with your wallet's private key
	chainId: 421614, // Chain ID for Arbitrum Sepolia
    },
  },
};

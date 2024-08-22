# Capture the Flag Solidity Project

This project implements a "Capture the Flag" game using Solidity smart contracts. The project includes the following contracts:

- `CaptureTheFlag.sol`: The main game contract that manages the game state and player interactions.
- `PlayerContract.sol`: An abstract contract that defines the interface for player interactions.
- `PlayerFlagStructs.sol`: A Solidity file that contains the data structures (structs) used in the game.

## Prerequisites

Before setting up the project, ensure you have the following installed:

- [Node.js and npm](https://nodejs.org/) (Node.js version >= 12.0.0)
- [Git](https://git-scm.com/)

## Getting Started

### 1. Clone the Repository

Clone the project repository to your local machine:

```bash
git clone https://github.com/yourusername/CaptureTheFlag.git
cd CaptureTheFlag
```

### 2. Install Dependencies

Navigate to the project directory and install the required npm packages:

```bash
npm install
```

### 3. Set Up Environment Variables

Create a `.env` file in the root of your project directory and add the following environment variables:

```plaintext
PRIVATE_KEY=your_private_key_here
```

- `PRIVATE_KEY`: Your Ethereum account's private key (without the `0x` prefix).

### 4. Compile the Contracts

Compile the Solidity contracts using Hardhat:

```bash
npx hardhat compile
```

### 5. Deploy Contracts

Deploy the contracts to the Arbitrum Sepolia testnet:

```bash
npx hardhat run scripts/deploy.js --network arbitrumSepolia
```

After deploying, you will see the deployed contract addresses in the console output.

### 6. Interacting with the Contracts

You can interact with the deployed contracts using the Hardhat console or by writing additional scripts. For example, to interact with the `CaptureTheFlag` contract using the Hardhat console:

```bash
npx hardhat console --network arbitrumSepolia
```

Then, in the console:

```javascript
const CaptureTheFlag = await ethers.getContractFactory("CaptureTheFlag");
const captureTheFlag = await CaptureTheFlag.attach("deployed_contract_address");

// Call functions on the contract
```

### 7. Running Tests

You can write and run tests for your contracts in the `test/` directory using the following command:

```bash
npx hardhat test
```

## Project Structure

- `contracts/`: Contains the Solidity contracts.
  - `CaptureTheFlag.sol`: The main game contract.
  - `PlayerContract.sol`: The abstract contract for player interactions.
  - `PlayerFlagStructs.sol`: Data structures used in the game.
- `scripts/`: Contains deployment scripts.
  - `deploy.js`: Script to deploy the contracts to a specified network.
- `test/`: Contains test scripts.
- `hardhat.config.js`: Hardhat configuration file.
- `.env`: Environment variables (not included in the repository).

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## License

This project is licensed under the MIT License.

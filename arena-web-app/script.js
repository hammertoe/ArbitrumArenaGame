// 1c463129882e43dd9c641c38fb25f332
let provider;
let wsProvider;
let signer;
let arenaContract;
let arenaAbi;
let arenaAddress = '0xCd82cE99045CaC23481677749F88AEd5ef35c1Fe';
let gridSize = 10;
let registeredPlayers = new Map(); // Store player info using address as key

// Enhanced color palette for up to 30 players
const playerColors = [
    '#FF0000', '#0000FF', '#00FF00', '#FFD700', '#FF00FF', '#00FFFF', '#FF8C00', '#4B0082', 
    '#32CD32', '#DC143C', '#9370DB', '#20B2AA', '#FF6347', '#4169E1', '#2E8B57', '#BA55D3',
    '#CD853F', '#008B8B', '#8B0000', '#483D8B', '#556B2F', '#9932CC', '#8B4513', '#008080',
    '#FF4500', '#4682B4', '#3CB371', '#9400D3', '#DAA520', '#5F9EA0'
];

// Map to store player colors
const playerColorMap = new Map();

// Function to get a distributed set of colors for players
function getDistributedColors(numPlayers) {
    if (numPlayers <= 0) return [];
    if (numPlayers >= playerColors.length) return playerColors;

    const step = Math.floor(playerColors.length / numPlayers);
    const distributedColors = [];

    for (let i = 0; i < numPlayers; i++) {
        const index = (i * step) % playerColors.length;
        distributedColors.push(playerColors[index]);
    }

    return distributedColors;
}

// Function to update the colors for each player
function updatePlayerColors(players) {
    playerColorMap.clear();
    const activeColors = getDistributedColors(players.length);
    players.forEach((player, index) => {
        playerColorMap.set(player.playerAddress, activeColors[index]);
    });
}

// Function to get a player's color based on their address
function getPlayerColor(playerAddress) {
    return playerColorMap.get(playerAddress) || '#CCCCCC';
}

// Load the ABI for the Arena contract
fetch('arenaAbi.json')
    .then(response => response.json())
    .then(data => {
        arenaAbi = data;
    })
    .catch(error => {
        console.error('Error loading ABI:', error);
    });

document.getElementById('connect-wallet').addEventListener('click', async () => {
    if (typeof window.ethereum !== 'undefined') {
        // Connect to MetaMask using Web3Provider
        await window.ethereum.request({ method: 'eth_requestAccounts' });
        const web3Provider = new ethers.providers.Web3Provider(window.ethereum);
        signer = web3Provider.getSigner();

        // Get the wallet address to display
        const walletAddress = await signer.getAddress();
        document.getElementById('wallet-address').innerText = `Connected: ${walletAddress}`;

        // Create a WebSocketProvider for listening to contract events
        const wsUrl = "wss://arbitrum-sepolia.infura.io/ws/v3/1c463129882e43dd9c641c38fb25f332"; // Replace with your network's WebSocket URL
        wsProvider = new ethers.providers.WebSocketProvider(wsUrl);

        // Use the signer (from Web3Provider) with the WebSocketProvider to create the contract instance
        arenaContract = new ethers.Contract(arenaAddress, arenaAbi.abi, signer);
        
        // Set up event listeners using the WebSocketProvider
        setupEventListeners();

        console.log('Connected to contract at:', arenaAddress);
    } else {
        alert('Please install MetaMask or another Ethereum wallet.');
    }
});

document.getElementById('start-game').addEventListener('click', async () => {
    try {
        const tx = await arenaContract.startGame();
        const receipt = await tx.wait();
        //console.log(receipt);
        //const event = receipt.events.find(event => event.event === 'TurnPlayed');
        //const [turn, playerAddrs, xs, ys, healths] = event.args;
        //await updateArena(playerAddrs, xs, ys, healths);
        alert('Game started!');
    } catch (error) {
        console.error('Error starting game:', error);
        alert('Error starting game. See console for details.');
    }
});

// Listen for the 'TurnPlayed' event and update the arena
async function setupEventListeners() {
    // Create a contract instance using the WebSocket provider just for listening to events
    const arenaContractWs = new ethers.Contract(arenaAddress, arenaAbi.abi, wsProvider);

    arenaContractWs.on('TurnPlayed', async (turnNumber, playerAddrs, xs, ys, healths, event) => {
        console.log(`Turn ${turnNumber}`);
        await updateArena(playerAddrs, xs, ys, healths);
    });
    
    arenaContractWs.on('GameEnded', async (winner, event) => {
        console.log(`Game ended! Winner: ${winner}`);
        alert(`Game ended! Winner is ${winner}`);
    });

    console.log("set up event listeners");

    console.log(wsProvider._events);

    }

async function updateArena(playerAddrs, xs, ys, healths) {

    const arenaDiv = document.getElementById('arena-grid');

    gridSize = Number(await arenaContract.gridSize());

    const players = [];
    for (let i = 0; i < playerAddrs.length; i++) {
        if (Number(healths[i] > 0)) {
            const playerAddr = playerAddrs[i];
            const playerInfo = registeredPlayers.get(playerAddr) || { name: `Player ${i + 1}` };
            players.push({
                playerAddress: playerAddr,
                name: playerInfo.name,
                x: Number(xs[i]),
                y: Number(ys[i]),
                health: Number(healths[i]),
            });
        }
    }

    updatePlayerColors(players);

    const grid = [];
    for (let y = 0; y < gridSize; y++) {
        grid[y] = [];
        for (let x = 0; x < gridSize; x++) {
            grid[y][x] = null;
        }
    }

    for (const player of players) {
        const x = player.x;
        const y = player.y;
        grid[y][x] = player;
    }

    arenaDiv.innerHTML = '';

    for (let y = gridSize - 1; y >= 0; y--) {
        const rowDiv = document.createElement('div');
        rowDiv.className = 'row';

        for (let x = 0; x < gridSize; x++) {
            const cellDiv = document.createElement('div');
            cellDiv.className = 'cell';

            const player = grid[y][x];
            if (player) {
                const playerDiv = document.createElement('div');
                playerDiv.className = 'player';
                const color = getPlayerColor(player.playerAddress);
                playerDiv.style.backgroundColor = color;
                playerDiv.style.border = '1px solid rgba(0,0,0,0.2)';
                playerDiv.title = `Name: ${player.name}\nAddress: ${player.playerAddress}\nHealth: ${player.health}`;
                cellDiv.appendChild(playerDiv);
            }

            rowDiv.appendChild(cellDiv);
        }
        arenaDiv.appendChild(rowDiv);
    }
}

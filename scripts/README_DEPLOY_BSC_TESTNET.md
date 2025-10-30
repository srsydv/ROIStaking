Setup for BNB Testnet (chainId 97)

1) Create a .env file in the project root with:

   BSC_TESTNET_RPC_URL=https://data-seed-prebsc-2-s3.binance.org:8545
   BSC_TESTNET_PRIVATE_KEY=0xYOUR_PRIVATE_KEY

   Notes:
   - Use a fresh test wallet; never share mainnet keys.
   - Fund it with BNB testnet from a faucet.

2) Install dotenv if not present:

   npm install --save-dev dotenv

3) Deploy to BSC Testnet:

   npx hardhat run scripts/deploy.js --network bscTestnet

4) Expected output will print both TestToken and ROIStaking addresses.



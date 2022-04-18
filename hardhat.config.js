require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-web3");
require("dotenv").config();

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

//Declare your .env variables here
const { PRIVATE_KEY, ETHERSCAN_API_KEY, POLYGON_MAINNET_RPC_URL, POLYGON_TESTNET_RPC_URL } =
  process.env;
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

module.exports = {
  networks: {
    hardhat: {},
    localhost: {
      url: "http://localhost:8545",
    },
    matic: {
      url: POLYGON_MAINNET_RPC_URL,
      accounts: [`0x${PRIVATE_KEY}`],
    },
    mumbai: {
      url: POLYGON_TESTNET_RPC_URL,
      accounts: [`0x${PRIVATE_KEY}`],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 20000,
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};

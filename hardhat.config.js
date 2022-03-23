require("dotenv").config();
const { task } = require("hardhat/config");
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    goerli: {
      chainId: 5,
      url: process.env.NETWORK_ENDPOINT_GOERLI,
      accounts: [process.env.ACCOUNT_PK],
    },
    rinkeby: {
      chainId: 4,
      url: process.env.NETWORK_ENDPOINT_RINKEBY,
      accounts: [process.env.ACCOUNT_PK],
    },
    // TODO: uncomment when shipping to mainnet
    // mainnet: {
    //   chainId: 1,
    //   url: process.env.NETWORK_ENDPOINT_MAINNET,
    //   accounts: [process.env.ACCOUNT_PK],
    // },
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY,
      rinkeby: process.env.ETHERSCAN_API_KEY,
      // TODO: uncomment when shipping to mainnet
      // mainnet: process.env.ETHERSCAN_API_KEY,
    },
  },
};

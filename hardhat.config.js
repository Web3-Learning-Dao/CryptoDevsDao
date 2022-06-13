require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('@nomiclabs/hardhat-ethers');
require("dotenv").config({ path: "./hardhat-tutorial/hardhat-tutorial.env" });
require('hardhat-deploy');
const {HardhatUserConfig} = require('hardhat/types');

const RINKEBY_API_KEY_URL = process.env.RINKEBY_API_KEY_URL;
const RINKEBY_PRIVATE_KEY = process.env.RINKEBY_PRIVATE_KEY;

const ROPSTEN_API_KEY_URL = process.env.ROPSTEN_API_KEY_URL;
const ROPSTEN_PRIVATE_KEY = process.env.ROPSTEN_PRIVATE_KEY;

const ETHMAINNET_API_KEY_URL = process.env.ETHMAINNET_API_KEY_URL;

const ETHERSCAN_KEY = process.env.ETHERSCAN_KEY;

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
 const config = {
  solidity: {
    version:"0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      },
    },
  },

  // Named accounts for plugin `hardhat-deploy`
  namedAccounts: {
    deployer: 0,
    tokenOwner: 1,
    play1: 2,
  },

  // Rewrite the `./test` folder to `./tests`
  paths: {
    tests: './tests',
    sources: 'contracts',
  },

  networks: {
    hardhat:{
      forking: {
        url: ETHMAINNET_API_KEY_URL,//分叉主网，总是进行
        blockNumber: 14930000 //用于锁定区块号，提高测试稳定性和速度
      }
    },
    rinkeby:{
      url: RINKEBY_API_KEY_URL,
      accounts: [RINKEBY_PRIVATE_KEY],
    },
    ropsten:{
      url: ROPSTEN_API_KEY_URL,
      accounts: [ROPSTEN_PRIVATE_KEY],
    },
    localhost: {
      url: 'http://localhost:8545',
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey:ETHERSCAN_KEY,
  },

};
module.exports = config;
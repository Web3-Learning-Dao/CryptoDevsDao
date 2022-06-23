const fs = require('fs');
const { utils } = require('ethers');
const { isAddress, getAddress, formatUnits, parseUnits } = utils;
require("dotenv").config({ path: "./hardhat-tutorial/hardhat-tutorial.env" });

module.exports.testArgs = function (){
    return [
        {
            name: 'CryptoDevsToken',
            symbol: 'CDT',
        },
        {
            name: 'CryptoDevsNFT',
            symbol: 'CDNFT',
        },
        {
            /// @dev for testing purposes only
            timelockDelay: 1,
            cryptoDevsToken: {
                initialSupply: 1000000,
                initialSplit: {
                  members: 20,
                  investors: 10,
                  market: 30,
                  reserved: 40,
                },
                governor: {
                  votingDelay: 1000,
                  votingPeriod: 10000,
                  quorumNumerator: 4,
                  proposalThreshold: 100,
                },
              },
              cryptoDevsNFT: {
                /// @dev: for testing purposes only
                governor: {
                  votingDelay: 0,
                  votingPeriod: 2,
                  quorumNumerator: 3,
                  proposalThreshold: 1,
                },
                enableMembershipTransfer: false,
                baseTokenURI: '',
                contractURI: '',
              },
              investment: {
                enableInvestment: true,
                investThresholdInETH: 1,
                investRatioInETH: 2,
                investInERC20: [],
                investThresholdInERC20: [],
                investRatioInERC20: [],
              },
              whitelist:{
                maxWhitelistNum: 100,
              },
        },
    ];
};

module.exports.node_url = function (networkName) {
  if (networkName) {
    const uri = process.env[networkName.toUpperCase() + '_API_KEY_URL'];
    if (uri && uri !== '') {
      return uri;
    }
  }

  let uri = process.env.ETH_NODE_URI;
  if (uri) {
    uri = uri.replace('{{networkName}}', networkName);
  }
  if (!uri || uri === '') {
    if (networkName === 'localhost') {
      return 'http://localhost:8545';
    }
    return '';
  }
  if (uri.indexOf('{{') >= 0) {
    throw new Error(
      `invalid uri or network not supported by nod eprovider : ${uri}`
    );
  }
  return uri;
}

function getMnemonic(networkName) {
  if (networkName) {
    const mnemonic = process.env[networkName.toUpperCase() + '_PRIVATE_KEY'];
    if (mnemonic && mnemonic !== '') {
      return mnemonic;
    }
  }

  const mnemonic = process.env.MNEMONIC;
  if (!mnemonic || mnemonic === '') {
    return 'test test test test test test test test test test test junk';
  }
  return mnemonic;
}

module.exports.accounts = function (networkName) {
  return {mnemonic: getMnemonic(networkName)};
}

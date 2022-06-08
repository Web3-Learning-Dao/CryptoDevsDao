const fs = require('fs');
const { utils } = require('ethers');
const { isAddress, getAddress, formatUnits, parseUnits } = utils;

module.exports.testArgs = function (){
    return [
        {
            name: 'CryptoDevsToken',
            symbol: 'CDT',
        },
        {
            name: 'CryptoDevsNFT',
            symbol: 'CDN',
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
        },
    ];
};
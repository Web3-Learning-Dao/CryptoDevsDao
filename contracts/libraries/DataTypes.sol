//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library DataTypes {

    // Basic token settings
    struct BaseToken {
        string name;
        string symbol;
    }

   struct WhitelistSettings{
       uint8 maxWhitelistNum;
    }

    // DAO's shareholding setting
    // @notice: [0:100] is the range of the percentage of the total supply
    struct ShareSplit {
        uint8 members;
        uint8 investors;
        uint8 market;
        uint8 reserved;
    }

    // Governance and voting-related settings
    struct GovernorSettings {
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 quorumNumerator;
        uint256 proposalThreshold;
    }

    struct CryptoDevsTokenSettings {
        GovernorSettings governor;
        uint256 initialSupply;
        ShareSplit initialSplit;
    }

    struct CryptoDevsNFTSettings {
        GovernorSettings governor;
        bool enableMembershipTransfer;
        string baseTokenURI;
        // OpenSea contract URI, See https://docs.opensea.io/docs/contract-level-metadata
        string contractURI;
    }

    // Whether to allow DAO's vault to support funding with eth or erc20 token
    struct InvestmentSettings {
        bool enableInvestment;
        uint256 investThresholdInETH;
        uint256 investRatioInETH;
        address[] investInERC20;
        uint256[] investThresholdInERC20;
        uint256[] investRatioInERC20;
    }

    // DAO Global Settings Entry
    struct DAOSettings {
        uint256 timelockDelay;
        CryptoDevsTokenSettings cryptoDevsToken;
        CryptoDevsNFTSettings cryptoDevsNFT;
        InvestmentSettings investment;
        WhitelistSettings whitelist;
    }

}
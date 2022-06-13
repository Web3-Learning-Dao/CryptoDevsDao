// SPDX-License-Identifier: MITs
pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import {Treasury} from './core/Treasury.sol';
import {TreasuryGovernor} from './core/Governor.sol';
import {CryptoDevsToken} from './core/CryptoDevsToken.sol';
import {CryptoDevsNFT} from './core/CryptoDevsNFT.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Constants} from './libraries/Constants.sol';
import {Errors} from './libraries/Errors.sol';
import {Events} from './libraries/Events.sol';

import {Whitelist} from './Whitelist.sol';

contract CryptoDevsEntrance is Context, AccessControlEnumerable,Pausable,Multicall {
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Governance related contracts
    Treasury public immutable treasury;
    TreasuryGovernor public immutable governorNFT;
    CryptoDevsToken public immutable cryptoDevsToken;
    CryptoDevsNFT public immutable cryptoDevsNFT;
    TreasuryGovernor public immutable governorToken;
    Whitelist public  immutable whitelist;

    /// @dev keccak256('PAUSER_ROLE')
    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;

    DataTypes.DAOSettings private _initialSettings;

    constructor(
        DataTypes.BaseToken memory cryptoDevsTokenBase,
        DataTypes.BaseToken memory cryptoDevsNFTBase,
        DataTypes.DAOSettings memory settings
    ){
        _initialSettings = settings;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
    
        // Create DAO's share token
        cryptoDevsToken = new CryptoDevsToken(
            bytes(cryptoDevsTokenBase.name).length > 0
                ? cryptoDevsTokenBase.name
                : string(
                    abi.encodePacked(cryptoDevsNFTBase.name, Constants.CRYPTODEVS_TOKEN_NAME_DEFAULT_SUFFIX)
                ),
            bytes(cryptoDevsTokenBase.symbol).length > 0
                ? cryptoDevsTokenBase.symbol
                : string(
                    abi.encodePacked(cryptoDevsNFTBase.symbol, Constants.CRYPTODEVS_TOKEN_SYMBOL_DEFAULT_SUFFIX)
                )
        );

        // Create DAO's share token
        cryptoDevsNFT = new CryptoDevsNFT(
            settings.cryptoDevsNFT.baseTokenURI,
            bytes(cryptoDevsNFTBase.name).length > 0
                ? cryptoDevsNFTBase.name
                : string(
                    abi.encodePacked(cryptoDevsTokenBase.name, Constants.CRYPTODEVS_TOKEN_NAME_DEFAULT_SUFFIX)
                ),
            bytes(cryptoDevsNFTBase.symbol).length > 0
                ? cryptoDevsNFTBase.symbol
                : string(
                    abi.encodePacked(cryptoDevsTokenBase.symbol, Constants.CRYPTODEVS_TOKEN_SYMBOL_DEFAULT_SUFFIX)
                )
        );

        // Create DAO's Treasury contract
        treasury = new Treasury({
            timelockDelay: settings.timelockDelay,
            cryptoDevsNFTAddress: address(cryptoDevsNFT),
            cryptoDevsTokenAddress: address(cryptoDevsToken),
            settings: settings.investment
        });

        // Create DAO's 1/1 nft Governance contract
        governorNFT = new TreasuryGovernor({
            name: string(abi.encodePacked(cryptoDevsNFTBase.name, Constants.MEMBERSHIP_GOVERNOR_SUFFIX)),
            token: cryptoDevsNFT,
            treasury: treasury,
            settings: settings.cryptoDevsNFT.governor
        });

        // Create DAO's token Governance
        governorToken = new TreasuryGovernor({
            name: string(abi.encodePacked(cryptoDevsTokenBase.name, Constants.TOKEN_GOVERNOR_SUFFIX)),
            token: cryptoDevsToken,
            treasury: treasury,
            settings: settings.cryptoDevsToken.governor
        });

        whitelist = new Whitelist(settings.whitelist.maxWhitelistNum,_msgSender());

    }

    /**
     * @dev setup governor roles for the DAO
     */
    function setupGovernor() public onlyRole(DEFAULT_ADMIN_ROLE) {
        /// @dev keccak256('PROPOSER_ROLE');
        bytes32 PROPOSER_ROLE = 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1;

        /// @dev keccak256('MINTER_ROLE');
        bytes32 MINTER_ROLE = 0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6;

        // Setup governor roles
        // Both membership and share governance have PROPOSER_ROLE by default
        treasury.grantRole(PROPOSER_ROLE, address(governorNFT));
        treasury.grantRole(PROPOSER_ROLE, address(governorToken));

        // Mint initial tokens to the treasury
        if (_initialSettings.cryptoDevsToken.initialSupply > 0) {
            cryptoDevsToken.mint(address(treasury), _initialSettings.cryptoDevsToken.initialSupply);
            treasury.updateShareSplit(_initialSettings.cryptoDevsToken.initialSplit);
        }

        // Revoke `TIMELOCK_ADMIN_ROLE` from this deployer
        // keccak256('TIMELOCK_ADMIN_ROLE')
        treasury.revokeRole(
            0x5f58e3a2316349923ce3780f8d587db2d72378aed66a8261c916544fa6846ca5,
            address(this)
        );

        // Make sure the DAO's Treasury contract controls everything
        grantRole(DEFAULT_ADMIN_ROLE, address(treasury));
        cryptoDevsToken.grantRole(DEFAULT_ADMIN_ROLE, address(treasury));
        cryptoDevsToken.grantRole(MINTER_ROLE, address(treasury));
        cryptoDevsToken.grantRole(PAUSER_ROLE, address(treasury));
        cryptoDevsToken.revokeRole(MINTER_ROLE, address(this));
        cryptoDevsToken.revokeRole(PAUSER_ROLE, address(this));
        cryptoDevsToken.revokeRole(DEFAULT_ADMIN_ROLE, address(this));

        // All membership NFT is set to be non-transferable by default
        if (!_initialSettings.cryptoDevsNFT.enableMembershipTransfer) {
            pause();
        }

        revokeRole(PAUSER_ROLE, _msgSender());
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // reserved the INVITER_ROLE case we need it to modify the whitelist by a non-admin deployer address.
    }

    function pause() public {
        if (!hasRole(PAUSER_ROLE, _msgSender())) revert Errors.NotPauser();

        _pause();
    }

    function unpause() public {
        if (!hasRole(PAUSER_ROLE, _msgSender())) revert Errors.NotPauser();

        _unpause();
    }

    function updateWhitelistAddress(bytes32 merkleTreeRoot_) external onlyRole(DEFAULT_ADMIN_ROLE){
        whitelist.updateWhitelist(merkleTreeRoot_);
    }
    
}
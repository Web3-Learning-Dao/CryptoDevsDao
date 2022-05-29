//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts/governance/TimelockController.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {ICryptoDevsNFT} from './interface/ICryptoDevsNFT.sol';
import {ICryptoDevsToken} from './interface/ICryptoDevsToken.sol';
import {DataTypes} from './libraries/DataTypes.sol';
import {Errors} from './libraries/Errors.sol';
import {Events} from './libraries/Events.sol';

contract Treasury is TimelockController, Multicall {
    using Address for address payable;
    address public immutable cryptoDevsToken;
    address public immutable cryptoDevsNFT;
    DataTypes.ShareSplit public shareSplit;
    DataTypes.InvestmentSettings public investmentSettings;

    address[] private _proposers;
    address[] private _executors = [address(0)];

    mapping(address => uint256) private _investThresholdInERC20;
    mapping(address => uint256) private _investRatioInERC20;

    constructor(
        uint256 timelockDelay,
        address cryptoDevsNFTAddress,
        address cryptoDevsTokenAddress,
        DataTypes.InvestmentSettings memory settings
    )TimelockController(timelockDelay, _proposers, _executors) {
        cryptoDevsToken = cryptoDevsTokenAddress;
        cryptoDevsNFT = cryptoDevsNFTAddress;
        investmentSettings = settings;
        _mappingSettings(settings);
    }

    modifier investmentEnabled() {
        if (!investmentSettings.enableInvestment) revert Errors.InvestmentDisabled();
        _;
    }

    function updateShareSplit(DataTypes.ShareSplit memory _shareSplit) public onlyRole(TIMELOCK_ADMIN_ROLE){
        shareSplit = _shareSplit;
    }

    /**
     * @dev Shortcut method
     * Allows distribution of shares to members in corresponding proportions (index is tokenID)
     * must be called by the timelock itself (requires a voting process)
     */
    function vestingShare(uint256[] calldata tokenId, uint8[] calldata shareRatio) public onlyRole(TIMELOCK_ADMIN_ROLE){
        uint256 _shareTreasury = ICryptoDevsToken(cryptoDevsToken).balanceOf(address(this));
        
        if (_shareTreasury == 0) revert Errors.NoShareInTreasury();

        uint256 _membersShare = _shareTreasury * (shareSplit.members / 100);

        if (_membersShare == 0) revert Errors.NoMembersShareToVest();

        for (uint256 i = 0; i < tokenId.length; i++) {
            address _member = ICryptoDevsNFT(cryptoDevsNFT).ownerOf(tokenId[i]);
            ICryptoDevsToken(cryptoDevsToken).transfer(_member, (_membersShare * shareRatio[i]) / 100);
        }
    }

    /**
     * @dev Shortcut method
     * to update settings for investment (requires a voting process)
     * @param settings - InvestmentSettings
     */
    function updateInvestmentSettings(DataTypes.InvestmentSettings memory settings) public onlyRole(TIMELOCK_ADMIN_ROLE){
        investmentSettings = settings;
        _mappingSettings(settings);
    }

    /**
     * @dev Invest in ETH
     * Allows external investors to transfer to ETH for investment.
     * ETH will issue share token of DAO at a set rate
     */
    function invest() external payable investmentEnabled {
        if (investmentSettings.investRatioInETH == 0) revert Errors.InvestmentDisabled();

        if (msg.value < investmentSettings.investThresholdInETH)
            revert Errors.InvestmentThresholdNotMet(investmentSettings.investThresholdInETH);

        _invest(msg.value / investmentSettings.investRatioInETH, address(0), msg.value);
    }

    /**
     * @dev Invest in ETH
     * Allows external investors to transfer to ETH for investment.
     * ETH will issue share token of DAO at a set rate
     * @param token - CryptoDevsToken address
     */
    function investInERC20(address token) external investmentEnabled{
        if (_investRatioInERC20[token] == 0) revert Errors.InvestmentInERC20Disabled(token);

        uint256 _radio = _investRatioInERC20[token];

        if (_radio == 0) revert Errors.InvestmentInERC20Disabled(token);

        uint256 _threshold = _investThresholdInERC20[token];
        uint256 _allowance = ICryptoDevsToken(token).allowance(_msgSender(), address(this));

        if (_allowance < _threshold)
            revert Errors.InvestmentInERC20ThresholdNotMet(token, _threshold);

        ICryptoDevsToken(token).transferFrom(_msgSender(), address(this), _allowance);
        _invest(_allowance / _radio, token, _allowance);
    }

    /**
     * @dev Private method of realizing external investments
     * The converted share token is automatically transferred to the external investor,
     * and if there are not enough shares in the vault, additional shares are automatically issued.
     * At the same time, the act of investing will mint a new investor status NFT membership card,
     * ensuring that the investor can participate in the voting of board members (1/1 NFT Votes).
     *
     * @param _shareTobeClaimed - the share token for the send to investor,
     *  _token - cryptoDevsToken address
     * _amount - investor send token amount
     */
    function _invest(
        uint256 _shareTobeClaimed,
        address _token,
        uint256 _amount
    ) private {
        uint256 _shareTreasury = ICryptoDevsToken(cryptoDevsToken).balanceOf(address(this));

        if (_shareTreasury < _shareTobeClaimed) {
            ICryptoDevsToken(cryptoDevsToken).mint(address(this), _shareTobeClaimed - _shareTreasury);
        }

        ICryptoDevsToken(cryptoDevsToken).transfer(_msgSender(), _shareTobeClaimed);
        ICryptoDevsNFT(cryptoDevsToken).investMint(_msgSender());

        if (_token == address(0)) {
            emit Events.InvestInETH(_msgSender(), msg.value, _shareTobeClaimed);
        } else {
            emit Events.InvestInERC20(_msgSender(), _token, _amount, _shareTobeClaimed);
        }
    }

 // @dev mapping arrays to maps cause of the lack of support of params mapping in Solidity
    function _mappingSettings(DataTypes.InvestmentSettings memory settings) private {
        if (settings.investInERC20.length > 0) {
            for (uint256 i = 0; i < settings.investInERC20.length; i++) {
                address _token = settings.investInERC20[i];
                _investThresholdInERC20[_token] = settings.investThresholdInERC20[i];
                _investRatioInERC20[_token] = settings.investRatioInERC20[i];
            }
        }
    }
    
}
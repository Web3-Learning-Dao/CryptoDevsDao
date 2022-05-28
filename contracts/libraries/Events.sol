//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Events {

    // Investment-related events
    event InvestorAdded(address indexed investor, uint256 indexed tokenId, uint256 timestamp);

    event InvestInETH(address indexed investor, uint256 amount, uint256 shareAmount);

    event InvestInERC20(
        address indexed investor,
        address indexed tokenAddress,
        uint256 amount,
        uint256 shareAmount
    );
    
}
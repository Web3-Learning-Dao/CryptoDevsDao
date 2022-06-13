// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface ICryptoDevsNFT is IERC721, IERC721Enumerable{

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function investMint(address to) external returns (uint256);

    function pause() external;

    function unpause() external;

    function startPresale() external;

    function setMintPrice(uint256 price) external;

    function getMintPrice() external returns (uint256);
    
    function setPresaleTime(uint256 persalTime) external;
   
}
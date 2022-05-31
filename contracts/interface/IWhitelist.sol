// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWhitelist {
    function whitelistedAddresses(address) external view returns (bool);

    function addAddressToWhitelist(address whiteAddress) external;

    function getALLWhiteListData() external view returns (address[] memory);

    function getWhilteListIssued(uint256 num) external returns (address[] memory);

    function updateWhitelist(bytes32 merkleTreeRoot_) external; 

    function checkMerkleTreeRootForWhitelist(bytes32[] calldata proof) external view returns (bool);
    
}
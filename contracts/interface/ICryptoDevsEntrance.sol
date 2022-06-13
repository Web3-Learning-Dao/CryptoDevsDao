//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ICryptoDevsEntrance {

    function setWhitelistAddress(address whitelistaddress ) external;

    function updateWhitelistAddress(bytes32 merkleTreeRoot_) external;
}
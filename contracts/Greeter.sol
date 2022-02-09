//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";

contract Greeter {
    string private greeting;
   
    address[] public WhilteList;

    constructor(string memory _greeting) {
        console.log("Deploying a Greeter with greeting:", _greeting);
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        console.log("Changing greeting from '%s' to '%s'", greeting, _greeting);
        greeting = _greeting;
    }

    function expand(uint256 randomValue, uint256 n) public pure returns (uint256[] memory expandedValues) {
    expandedValues = new uint256[](n);
    for (uint256 i = 0; i < n; i++) {
        expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)))%10;
    }
    return expandedValues;
}

    function getWhiteListData(uint256 num) public returns (address[] memory ){
       // require(requestIdToRandomNumber[AddressTorequestId[msg.sender]].isRet == true, "random is not ready!!");
        //Generate num random numbers for Chainlink random
        uint256 randomValue = 53033043951559633677511288179104004159099988387811303723152374354372773517071;
        //uint256[] memory expandedValues = new uint256[](num);
        uint256[] memory expandedValues = expand(randomValue,num);
        uint256 akfhk = expandedValues[0];
        for(uint i = 0;i < expandedValues.length;i++){
              WhilteList.push(msg.sender);
        }
    
        return WhilteList;
    }

}

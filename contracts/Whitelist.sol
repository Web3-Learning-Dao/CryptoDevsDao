// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import {Errors} from './libraries/Errors.sol';

contract Whitelist is Ownable,VRFConsumerBase,AccessControlEnumerable{

    uint256 totalWave;
    uint256 private seed;
    // _paused is used to pause the contract in case of an emergency
    bool public _paused;
    /*
    * A little magic, Google what events are in Solidity!
    */
    event NewWave(address indexed from, uint256 timestamp, string message);

    // Max number of whitelisted addresses allowed
    uint8 public maxWhitelistedAddresses;

    // Create a mapping of whitelistedAddresses
    // if an address is whitelisted, we would set it to true, it is false by default for all other addresses.
    mapping(address => bool) public whitelistedAddresses;
    address [] public NumTowhitelistedAddresses;
    address[] public WhilteList;

    /*
     * This is an address => uint mapping, meaning I can associate an address with a number!
     * In this case, I'll be storing the address with the last time the user waved at us.
     */
    mapping(address => uint256) public lastWavedAt;

    // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelisted
    uint256 public numAddressesWhitelisted;

    /*
     * I created a struct here named Wave.
     * A struct is basically a custom datatype where we can customize what we want to hold inside it.
     */
    struct Wave {
        address waver; // The address of the user who waved.
        string message; // The message the user sent.
        uint256 timestamp; // The timestamp when the user waved.
    }

    /*
     * I declare a variable waves that lets me store an array of structs.
     * This is what lets me hold all the waves anyone ever sends to me!
     */
    Wave[] waves;

    //Get a Random Number
    bytes32 internal keyHash;
    uint256 internal fee;

    /// @dev keccak256('INVITER_ROLE')
    bytes32 public constant INVITER_ROLE =
        0x639cc15674e3ab889ef8ffacb1499d6c868345f7a98e2158a7d43d23a757f8e0;


    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    // boolean to keep track of when presale started
    bool public presaleStarted;

    // timestamp for even presale would end
    uint256 public presaleEnded;

    // Setting the Max number of whitelisted addresses
    // User will put the value at the time of deployment
    constructor(uint8 _maxWhitelistedAddresses) payable VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709  // LINK Token
        ){
        maxWhitelistedAddresses =  _maxWhitelistedAddresses;
        console.log("maxWhitelistedAddresses [%d]!",maxWhitelistedAddresses);

        _grantRole(INVITER_ROLE, _msgSender());

        /*
            init seed 
        */
        seed = (block.timestamp + block.difficulty) % 100;
        console.log("init seed  %d",seed);

        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)

       // getRandomNumber();
    }

   /**
    * @dev startPresale starts a presale for the whitelisted addresses
    */
    function startPresale() public onlyOwner {
        presaleStarted = true;
        // Set presaleEnded time as current timestamp + 5 minutes
        // Solidity has cool syntax for timestamps (seconds, minutes, hours, days, years)
        presaleEnded = block.timestamp + 5 minutes;
    }

    /**
        addAddressToWhitelist - This function adds the address of the sender to the
        whitelist
    */
    function addAddressToWhitelist() private onlyWhenNotPaused {
        // check if the user has already been whitelisted
        require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");
        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an error.
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "More addresses cant be added, limit reached");
        // Add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[msg.sender] = false;
        NumTowhitelistedAddresses.push(msg.sender);
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }

    function waveWhiteliste(string memory _message) public onlyWhenNotPaused {

        /*
        * We need to make sure the current timestamp is at least 15-minutes bigger than the last timestamp we stored
        */
        require(lastWavedAt[msg.sender] + 1 minutes <= block.timestamp,"wave time is little 15 min, please wait!!");
        require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running");

        lastWavedAt[msg.sender] = block.timestamp;
        totalWave += 1;
        console.log("%s waved w/ message %s", msg.sender, _message);
        console.log("send address is [%s].!",msg.sender);

        /*
         * This is where I actually store the wave data in the array.
         */
        waves.push(Wave(msg.sender, _message, block.timestamp));

        /**
        *
        *addAddressToWhitelist
         */
        addAddressToWhitelist();

        /*
         * I added some fanciness here, Google it and try to figure out what it is!
         * Let me know what you learn in #general-chill-chat
         */
        emit NewWave(msg.sender, block.timestamp, _message);  
        
    }

    function getAllWaves() public view returns (Wave[] memory) {
        return waves;
    }

    function getTotalWaves() public view returns (uint256) {
         console.log("we have totalWaves is [].!",totalWave);
         return totalWave;
    } 

    /**
    * @dev setPaused makes the contract paused or unpaused
    */
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    struct Random {
        address addr; 
        uint256 rand; 
        bool isRet; 
    }

    mapping(bytes32 => Random) public requestIdToRandomNumber;
    mapping(address => bytes32) public AddressTorequestId;
    /** 
     * Requests randomness 
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        bytes32 Id = requestRandomness(keyHash, fee);
        requestIdToRandomNumber[Id].addr = msg.sender;
        requestIdToRandomNumber[Id].isRet = false;
        AddressTorequestId[msg.sender] = Id;
        return Id;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        requestIdToRandomNumber[requestId].rand = randomness;
        requestIdToRandomNumber[requestId].isRet = true;
        console.log("fulfillRandomness randomness is [%d].!",randomness);
    }

    function expand(uint256 randomValue, uint256 n) private view returns (uint256[] memory ) {
        uint256[] memory expandedValues = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            expandedValues[i] = uint256(keccak256(abi.encode(randomValue, i)))%numAddressesWhitelisted;
        }
        return expandedValues;
    }

    function getALLWhiteListData() public view onlyOwner returns (address[] memory){
        return NumTowhitelistedAddresses;
    }

    function getWhiteListData(uint256 num) public onlyOwner returns (address[] memory ){
        require(requestIdToRandomNumber[AddressTorequestId[msg.sender]].isRet == true, "random is not ready!!");
        //Generate num random numbers for Chainlink random
        uint256[] memory randomArrays = expand(requestIdToRandomNumber[AddressTorequestId[msg.sender]].rand,num);
        for(uint i=0;i<randomArrays.length;i++){
            address WhilteListAddress =  NumTowhitelistedAddresses[randomArrays[i]];
            WhilteList.push(WhilteListAddress);
            whitelistedAddresses[WhilteListAddress] = true;
        }
        return WhilteList;
    }

    //use merkle for whitelist
    bytes32 private _merkleTreeRoot;

    /**
     * @dev update whitelist by a back-end server bot
     */
    function updateWhitelist(bytes32 merkleTreeRoot_) public {
        if (!hasRole(INVITER_ROLE, _msgSender())) revert Errors.NotInviter();

        _merkleTreeRoot = merkleTreeRoot_;
    }

}
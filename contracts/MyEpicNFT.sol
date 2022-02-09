pragma solidity ^0.8.4;

// We first import some OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

// We need to import the helper functions from the contract that we copy/pasted.
import { Base64 } from "./libraries/Base64.sol";
import "./interface/IWhitelist.sol";

contract MyEpicNFT is ERC721URIStorage, Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string baseSvg = "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 24px; }</style><rect width='100%' height='100%' fill='black' /><text x='50%' y='50%' class='base' dominant-baseline='middle' text-anchor='middle'>";

    // _paused is used to pause the contract in case of an emergency
    bool public _paused;

    // boolean to keep track of when presale started
    bool public presaleStarted;

    // timestamp for even presale would end
    uint256 public presaleEnded;

    string _baseTokenURI;

    // Whitelist contract instance
    IWhitelist whitelist;

    uint256 public maxTokenIds = 20;

    //  _price is the price of one Crypto Dev NFT
    uint256 public _price = 0.01 ether;

    // We need to pass the name of our NFTs token and its symbol.
    constructor(string memory baseURI, address whitelistContract) ERC721 ("SquareNFT", "SQUARE") {
        console.log("This is my NFT contract. Woah!");
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
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


    /*
    * A little magic, Google what events are in Solidity!
    */
    event newEpicNFTMinted(address indexed from, uint256 tokenId);


    string[] fistWords=["aa","bb","cc"];
    string[] secondWords=["11","22","33"];
    string[] lastWords=["AA","BB","CC"];

    function random(string memory input) public view returns (uint256){
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function pickRandomFirstWord(uint256 _tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("FIST_WORDS",Strings.toString(_tokenId))));
        rand = rand % fistWords.length;
        return fistWords[rand];
    }

    function pickRandomSecondWord(uint256 _tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("SECOND_WORDS",Strings.toString(_tokenId))));
        rand = rand % secondWords.length;
        return secondWords[rand];
    }

    function pickRandomLastWord(uint256 _tokenId) public view returns (string memory) {
        uint256 rand = random(string(abi.encodePacked("LAST_WORDS",Strings.toString(_tokenId))));
        rand = rand % lastWords.length;
        return lastWords[rand];
    }

    /**
    * @dev presaleMint allows an user to mint one NFT per transaction during the presale.
    */
    function presaleMint() public payable onlyWhenNotPaused {
        uint256 tokenId = _tokenIds.current();
        require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running");
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        require(tokenId < maxTokenIds, "Exceeded maximum Cypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        makeAnEpicNFT(tokenId);
    }

    /**
      * @dev mint allows an user to mint 1 NFT per transaction after the presale has ended.
      */
    function mint() public payable onlyWhenNotPaused {
        uint256 tokenId = _tokenIds.current();
        require(presaleStarted && block.timestamp >=  presaleEnded, "Presale has not ended yet");
        require(tokenId < maxTokenIds, "Exceed maximum Cypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        makeAnEpicNFT(tokenId);
    }

    function makeAnEpicNFT(uint256 newItemId) private {
        // Get the current tokenId, this starts at 0.

        string memory first = pickRandomFirstWord(newItemId);
        string memory second = pickRandomSecondWord(newItemId);
        string memory last = pickRandomLastWord(newItemId);
        string memory combinedWord =  string(abi.encodePacked(first, second, last));
        string memory finalSvg = string(abi.encodePacked(baseSvg, first, second, last, "</text></svg>"));

        // Get all the JSON metadata in place and base64 encode it.
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        // We set the title of our NFT as the generated word.
                        combinedWord,
                        '", "description": "A highly acclaimed collection of squares.", "image": "data:image/svg+xml;base64,',
                        // We add data:image/svg+xml;base64 and then append our base64 encode our svg.
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        // Just like before, we prepend data:application/json;base64, to our data.
        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log("\n--------------------");
        console.log(finalTokenUri);
        console.log("--------------------\n");


        // Actually mint the NFT to the sender using msg.sender.
        _safeMint(msg.sender, newItemId);

        // Set the NFTs data.
        //_setTokenURI(newItemId, "data:application/json;base64,==");
        _setTokenURI(newItemId,finalTokenUri);

        // Increment the counter for when the next NFT is minted.
        _tokenIds.increment();

        emit newEpicNFTMinted(msg.sender, newItemId);

        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);

    }

    /**
    * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
    * returned an empty string for the baseURI
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    * @dev setPaused makes the contract paused or unpaused
    */
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

   /**
      * @dev withdraw sends all the ether in the contract
      * to the owner of the contract
    */
    function withdraw() public onlyOwner  {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

}
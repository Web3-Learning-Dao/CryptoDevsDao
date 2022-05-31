// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// We first import some OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol';
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import "hardhat/console.sol";
// We need to import the helper functions from the contract that we copy/pasted.
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import "../interface/IWhitelist.sol";

contract CryptoDevsNFT is     
    Context,
    AccessControlEnumerable,
    Pausable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Votes,
    Ownable
{
    using Counters for Counters.Counter;
    using Strings for uint256;
    Counters.Counter private _tokenIdsforNFT;
    
    // boolean to keep track of when presale started
    bool public presaleStarted;
    // timestamp for even presale would end
    uint256 public presaleEnded;
    uint256 _presaleTime = 1 days;
    
    uint256 public maxTokenIds = 10000;
    //  _price is the price of one Crypto Dev NFT
    uint256 public _price = 0.01 ether;

    string _baseTokenURI;
    mapping(uint256 => string) private _decentralizedStorage;
    mapping(uint256 => bool) private _isInvestor;

    // NFT Membership related states
    /// @dev keccak256('PAUSER_ROLE')
    bytes32 public constant PAUSER_ROLE =
        0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;
    /// @dev keccak256('INVITER_ROLE')
    bytes32 public constant INVITER_ROLE =
        0x639cc15674e3ab889ef8ffacb1499d6c868345f7a98e2158a7d43d23a757f8e0;

    // We need to pass the name of our NFTs token and its symbol.
    constructor(string memory baseURI,string memory nftName,string memory symbol) 
    ERC721(nftName, symbol)
    EIP712(nftName,'1')
    {
        console.log("This is my NFT contract. Woah!");
        _baseTokenURI = baseURI;

        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(PAUSER_ROLE, _msgSender());
        _grantRole(INVITER_ROLE, _msgSender());

    }

    /**
    * @dev startPresale starts a presale for the whitelisted addresses
    */
    function startPresale() external onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleStarted = true;
        // Set presaleEnded time as current timestamp + 5 minutes
        // Solidity has cool syntax for timestamps (seconds, minutes, hours, days, years)
        presaleEnded = block.timestamp + _presaleTime;
    }

    function setMintPrice(uint256 price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _price = price;
    }

    function getMintPrice() external view returns (uint256){
        return _price;
    }

    function setPresaleTime(uint256 persalTime) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _presaleTime = persalTime;
    }

    /**
    * @dev Self-mint for white-listed members
    */
    function whiteListemint() public payable  {
        if (balanceOf(_msgSender()) > 0) revert Errors.MembershipAlreadyClaimed();
        uint256 tokenId = _tokenIdsforNFT.current();
       // require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted");
        require(tokenId < maxTokenIds, "Exceeded maximum Cypto Devs supply");
        //require(msg.value >= _price, "Ether sent is not correct");
        _mint(_msgSender(), tokenId);
        _tokenIdsforNFT.increment();
        
    }

    /**
      * @dev Self-mint for pubilc members
      */
    function publicMint() external payable  {
        if (balanceOf(_msgSender()) > 0) revert Errors.MembershipAlreadyClaimed();
        uint256 tokenId = _tokenIdsforNFT.current();
        require(presaleStarted && block.timestamp >=  presaleEnded, "Presale has not ended yet");
        require(tokenId < maxTokenIds, "Exceed maximum Cypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        // tokenId start with 0
        _mint(_msgSender(), tokenId);
        _tokenIdsforNFT.increment();
    }

    /**
     * @dev Treasury could mint for a investor by pass the whitelist check
     */
    function investMint(address to) external onlyRole(DEFAULT_ADMIN_ROLE) returns (uint256) {
        if (balanceOf(to) > 0) {
            uint256 tokenId = tokenOfOwnerByIndex(to, 0);
            _isInvestor[tokenId] = true;
            emit Events.InvestorAdded(to, tokenId, block.timestamp);
            return tokenId;
        }

        uint256 _tokenId = _tokenIdsforNFT.current();
        _mint(to, _tokenId);
        _isInvestor[_tokenId] = true;
        emit Events.InvestorAdded(to, _tokenId, block.timestamp);
        _tokenIdsforNFT.increment();
        return _tokenId;
    }

/*
* @dev mint the NFT for svg photo test

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
        _tokenIdsforNFT.increment();

        emit newEpicNFTMinted(msg.sender, newItemId);

        console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);

    }
*/

    /**
     * @dev Switch for the use of decentralized storage
     */
    function updateTokenURI(uint256 tokenId, string calldata dataURI) public {
        require(_exists(tokenId), Errors.ERC721METADATA_UPDATE_NONEXIST_TOKEN);
        require(ownerOf(tokenId) == _msgSender(), Errors.ERC721METADATA_UPDATE_UNAUTH);

        _decentralizedStorage[tokenId] = dataURI;
    }
    
    /**
     * @dev Returns the DAO's membership token URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), Errors.ERC721METADATA_NONEXIST_TOKEN);

        string memory baseURI = _baseURI();

        if (bytes(_decentralizedStorage[tokenId]).length > 0) {
            // TODO: Support for multiple URIs like ar:// or ipfs://
            return
                string(
                    abi.encodePacked(
                        'data:application/json;base64,',
                        Base64.encode(bytes(_decentralizedStorage[tokenId]))
                    )
                );
        }

        return
            bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Returns if a tokenId is marked as investor
     */
    function isInvestor(uint256 tokenId) public view returns (bool) {
        return _isInvestor[tokenId];
    }

    /**
    * @dev _baseURI overides the Openzeppelin's ERC721 implementation which by default
    * returned an empty string for the baseURI
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public {
        if (!hasRole(PAUSER_ROLE, _msgSender())) revert Errors.NotPauser();

        _pause();
    }

    function unpause() public {
        if (!hasRole(PAUSER_ROLE, _msgSender())) revert Errors.NotPauser();

        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // @dev Pause status won't block mint operation
        if (from != address(0) && paused()) revert Errors.TokenTransferWhilePaused();
    }

    /**
     * @dev The functions below are overrides required by Solidity.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Votes) {
        super._afterTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
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
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract ArchtDAO is ERC721, ERC721URIStorage, AccessControl, EIP712, ERC721Votes {
    using Counters for Counters.Counter;
    
    // =========================================================================
    //                               Storage
    // =========================================================================

    //Count token id
    Counters.Counter private _tokenIdCounter;
    Counters.Counter public _totalSupply;
    
    //Token based URI, this generally leads to a json file storing necessary info from the token and holder
    string public baseURI = "";

    
    // =========================================================================
    //                               Roles
    // =========================================================================
    
    bytes32 public ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public MINTER_ROLE = keccak256("MINTER_ROLE");

    // =========================================================================
    //                               Constructor
    // =========================================================================

    //Constructor 
    constructor() ERC721("ArchtDAO", "ARCHT") EIP712("ArchtDAO", "1") {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    // =========================================================================
    //                               Functions
    // =========================================================================

    //Set roles to different address
    function setManager(address new_manager_address) public onlyRole(ADMIN_ROLE){
        _grantRole(ADMIN_ROLE, new_manager_address);
    }

    function setMinter(address minter_address) public onlyRole(ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minter_address);
    }

    //Return base URI for metadata storaga
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    
    }
    //Set token URI to store metadata
    function setBaseURI(string memory newBaseURI) public onlyRole(ADMIN_ROLE) {
        baseURI = newBaseURI;
    }

    //Return the current token URI
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    // Mint a membership card to the given address
    function mint(address to ) external {
        require(balanceOf(to) == 0, "This address already owns a token");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _totalSupply.increment();
    }

    function setURIforToken(uint256 tokenId, string memory _tokenURI) public onlyRole(ADMIN_ROLE) {
        _setTokenURI(tokenId, _tokenURI);
    }

    // This function makes all membership token untransferable
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721)
    {
        require(from == address(0), "Token not transferable");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }


    // Override the burn function to allow admin to burn any token
    function burn(uint256 tokenId) public virtual onlyRole(ADMIN_ROLE) {
        _burn(tokenId);
        _totalSupply.decrement();
    }

    // Ensure correct execution of _burn in inherited classes
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) onlyRole(ADMIN_ROLE){
        super._burn(tokenId);
    }

    // Return true if that address has membership of the DAO
    function checkMembership(address owner) public view returns (bool) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return balanceOf(owner) > 0;
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract base_erc721 is ERC721, Ownable {
    uint public lastMintedId;
    string public baseURI;

    constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = lastMintedId;
        unchecked {
            ++lastMintedId;
        }
        _safeMint(to, tokenId);
    }
    function safeMintTo(address to, uint tokenId) public onlyOwner {
        _safeMint(to, tokenId);
        unchecked {
            ++lastMintedId;
        }
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}
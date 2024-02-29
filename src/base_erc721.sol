// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract base_erc721 is ERC721, Ownable {
    string public baseURI;
    mapping (uint256 => MarketplaceDistribution) marketplaceDistributions;

    struct MarketplaceDistribution {
        uint16[] marketplaceDistributionRates;
        address[] marketplaceDistributionAddresses;
    }
    event MarketplaceDistributionSet(
        uint256 indexed tokenId,
        uint16[] marketplaceDistributionRates,
        address[] marketplaceDistributionAddresses
    );
    event BaseURISet(string baseURI);

    // -----------------------------------------------------------------------------

    constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {}

    function safeMintTo(address to, uint tokenId) public onlyOwner {
        _safeMint(to, tokenId);
    }

    function setBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
        emit BaseURISet(baseURI);
    }

    function setMarketplaceDistributions(
        uint256 _tokenId,
        uint16[] memory _marketplaceDistributionRates,
        address[] memory _marketplaceDistributionAddresses
    ) external onlyOwner {
        require(
            _marketplaceDistributionRates.length == _marketplaceDistributionAddresses.length,
            "MarketplaceDistribution: Rates and Addresses length mismatch"
        );
        marketplaceDistributions[_tokenId] = MarketplaceDistribution(
            _marketplaceDistributionRates,
            _marketplaceDistributionAddresses
        );
        emit MarketplaceDistributionSet(
            _tokenId,
            _marketplaceDistributionRates,
            _marketplaceDistributionAddresses
        );
    }

    // views

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function getMarketplaceDistributionForERC721(
        uint256 _tokenId
    ) external view returns(
        uint16[] memory, 
        address[] memory
    ) {
        return (
            marketplaceDistributions[_tokenId].marketplaceDistributionRates, 
            marketplaceDistributions[_tokenId].marketplaceDistributionAddresses
        );
    }
}
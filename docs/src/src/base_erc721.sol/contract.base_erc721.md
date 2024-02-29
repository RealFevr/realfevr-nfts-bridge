# base_erc721
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/087f6b3facb11b27f9b780abe00b57b13e133579/src\base_erc721.sol)

**Inherits:**
ERC721, Ownable


## State Variables
### baseURI

```solidity
string public baseURI;
```


### marketplaceDistributions

```solidity
mapping(uint256 => MarketplaceDistribution) marketplaceDistributions;
```


## Functions
### constructor


```solidity
constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender);
```

### safeMintTo


```solidity
function safeMintTo(address to, uint256 tokenId) public onlyOwner;
```

### setBaseURI


```solidity
function setBaseURI(string memory baseURI_) public onlyOwner;
```

### setMarketplaceDistributions


```solidity
function setMarketplaceDistributions(
    uint256 _tokenId,
    uint16[] memory _marketplaceDistributionRates,
    address[] memory _marketplaceDistributionAddresses
) external onlyOwner;
```

### _baseURI


```solidity
function _baseURI() internal view override returns (string memory);
```

### getMarketplaceDistributionForERC721


```solidity
function getMarketplaceDistributionForERC721(uint256 _tokenId)
    external
    view
    returns (uint16[] memory, address[] memory);
```

## Events
### MarketplaceDistributionSet

```solidity
event MarketplaceDistributionSet(
    uint256 indexed tokenId, uint16[] marketplaceDistributionRates, address[] marketplaceDistributionAddresses
);
```

### BaseURISet

```solidity
event BaseURISet(string baseURI);
```

## Structs
### MarketplaceDistribution

```solidity
struct MarketplaceDistribution {
    uint16[] marketplaceDistributionRates;
    address[] marketplaceDistributionAddresses;
}
```


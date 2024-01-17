# base_erc721
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/f2b769fdce542ef2e944020280170c83fef0a8d2/src\base_erc721.sol)

**Inherits:**
ERC721, Ownable


## State Variables
### lastMintedId

```solidity
uint256 public lastMintedId;
```


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

### safeMint


```solidity
function safeMint(address to) public onlyOwner;
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

## Structs
### MarketplaceDistribution

```solidity
struct MarketplaceDistribution {
    uint16[] marketplaceDistributionRates;
    address[] marketplaceDistributionAddresses;
}
```


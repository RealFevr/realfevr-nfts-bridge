# ERC721BridgeImpl
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/8845fdcd48bce6d81d3e7f792dea13fedb977a3a/src\ERC721BridgeImpl.sol)

**Inherits:**
ERC721Holder, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable

**Author:**
Krakovia - t.me/karola96

This contract is an erc721 bridge with optional fees


## State Variables
### OPERATOR

```solidity
bytes32 public OPERATOR;
```


### BRIDGE

```solidity
bytes32 public BRIDGE;
```


### isOnline

```solidity
bool public isOnline;
```


### feeActive

```solidity
bool public feeActive;
```


### feeReceiver

```solidity
address public feeReceiver;
```


### maxNFTsPerTx

```solidity
uint256 public maxNFTsPerTx;
```


### ethDepositFee

```solidity
mapping(uint256 chainId => ChainETHFee) public ethDepositFee;
```


### permittedNFTs

```solidity
mapping(address => NFTContracts) public permittedNFTs;
```


### permittedERC20s

```solidity
mapping(address => ERC20Tokens) public permittedERC20s;
```


### nftListPerContract

```solidity
mapping(address => mapping(uint256 => NFT)) public nftListPerContract;
```


### withdrawUniqueKeys

```solidity
mapping(string key => bool used) public withdrawUniqueKeys;
```


### mintUniqueKeys

```solidity
mapping(string key => bool used) public mintUniqueKeys;
```


### supportedChains

```solidity
mapping(uint256 chainId => bool supported) public supportedChains;
```


## Functions
### constructor


```solidity
constructor();
```

### _authorizeUpgrade


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE);
```

### initialize

initialize will set the role addresses


```solidity
function initialize(address _bridgeSigner, address _feeReceiver, address _operator) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_bridgeSigner`|`address`|address of the signer of the bridge|
|`_feeReceiver`|`address`|address of the fee receiver|
|`_operator`|`address`|address of the operator|


### setSupportedChain

set the supported chain

*only operator can call this*


```solidity
function setSupportedChain(uint256 chainId, bool status) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`chainId`|`uint256`|uint of the chain id|
|`status`|`bool`|bool to enable or disable the chain id|


### setMaxNFTsPerTx

max amount of NFTs that can be used in a tx

*only operator can call this*


```solidity
function setMaxNFTsPerTx(uint256 maxNFTsPerTx_) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maxNFTsPerTx_`|`uint256`|uint of the max amount of NFTs|


### setBridgeStatus

set the bridge status

*only operator can call this*


```solidity
function setBridgeStatus(bool active) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`active`|`bool`|bool to activate or deactivate the bridge|


### setFeeStatus

set the bridge fee statys

*only operator can call this*


```solidity
function setFeeStatus(bool active) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`active`|`bool`|bool to activate or deactivate the bridge|


### setETHFee

set the ETH fee on specified chain id

*only operator can call this*


```solidity
function setETHFee(uint256 chainId, bool status, uint256 amount) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`chainId`|`uint256`|uint of the chain id|
|`status`|`bool`|bool to activate or deactivate the fees|
|`amount`|`uint256`|uint of the fee amount|


### setTokenFees

set the fees for the ERC20 tokens

*only operator can call this*


```solidity
function setTokenFees(bool active, address nftAddress, uint256 depositFee, uint256 withdrawFee)
    external
    onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`active`|`bool`|bool to activate or deactivate the fees|
|`nftAddress`|`address`|address of the NFT Token|
|`depositFee`|`uint256`|uint to set the deposit fee for the bridge|
|`withdrawFee`|`uint256`|uint to set the withdraw fee for the bridge|


### setFeeReceiver

set the bridgeFee receiver

*only operator can call this*


```solidity
function setFeeReceiver(address receiver) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`receiver`|`address`|address of the fee receiver|


### setNFTDetails

set the settings of an NFT address

*only operator can call this*


```solidity
function setNFTDetails(
    bool isActive,
    address nftContractAddress,
    address feeTokenAddress,
    uint256 depositFeeAmount,
    uint256 withdrawFeeAmount
) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isActive`|`bool`|bool to activate or deactivate the NFT contract|
|`nftContractAddress`|`address`|address of the NFT contract|
|`feeTokenAddress`|`address`|address of the token to pay the fee|
|`depositFeeAmount`|`uint256`|uint of the deposit fee amount|
|`withdrawFeeAmount`|`uint256`|uint of the withdraw fee amount|


### setERC20Details

set the settings of an ERC20 address

*only operator can call this*


```solidity
function setERC20Details(bool isActive, address erc20ContractAddress) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`isActive`|`bool`|bool to activate or deactivate the ERC20 contract|
|`erc20ContractAddress`|`address`|address of the ERC20 contract|


### depositSingleERC721

deposit an ERC721 token to the bridge


```solidity
function depositSingleERC721(address nftAddress, uint256 tokenId, uint256 targetChainId) public payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|address of the NFT contract|
|`tokenId`|`uint256`|uint of the NFT id|
|`targetChainId`|`uint256`||


### depositMultipleERC721


```solidity
function depositMultipleERC721(address[] calldata nftAddress, uint256[] calldata tokenIds, uint256 targetChainId)
    external
    payable
    nonReentrant;
```

### withdrawSingleERC721

withdraw an ERC721 token from the bridge

*only bridgeSigner can call this*


```solidity
function withdrawSingleERC721(address to, address nftContractAddress, uint256 tokenId, string calldata uniqueKey)
    public
    onlyRole(BRIDGE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|address of the user to withdraw to|
|`nftContractAddress`|`address`|address of the NFT contract|
|`tokenId`|`uint256`|uint of the NFT id|
|`uniqueKey`|`string`||


### withdrawMultipleERC721

withdraw multiple ERC721 tokens from the bridge

*only bridgeSigner can call this*


```solidity
function withdrawMultipleERC721(
    address to,
    address contractAddress,
    uint256[] memory tokenIds,
    string[] calldata uniqueKeys
) external onlyRole(BRIDGE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|address of the user to withdraw to|
|`contractAddress`|`address`|address of the NFT contract|
|`tokenIds`|`uint256[]`|uint[] of the NFT ids|
|`uniqueKeys`|`string[]`||


### takeFees

take fees from the user


```solidity
function takeFees(address feeTokenAddress, uint256 fees, uint256 quantity) private returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`feeTokenAddress`|`address`|address of the token to take fees in|
|`fees`|`uint256`|amount of fees to take|
|`quantity`|`uint256`|number of NFTs to bridge|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint of the total cost of the bridge|


### getDepositFeeAddressAndAmount

get the fee token address and amount of fees for a given NFT contract


```solidity
function getDepositFeeAddressAndAmount(address contractAddress) external view returns (address, uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|nft contract address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|address of the fee token and amount of fees|
|`<none>`|`uint256`||


### createERC721

create a new ERC721 token owned by the bridge


```solidity
function createERC721(string calldata uri, string calldata name, string calldata symbol)
    public
    onlyRole(OPERATOR)
    returns (address nftAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`uri`|`string`|the uri of the new NFT|
|`name`|`string`|the name of the new NFT|
|`symbol`|`string`|the symbol of the new NFT|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|address of the new NFT contract|


### mintERC721

mint an ERC721 token to an user

*only bridge signer can call this*


```solidity
function mintERC721(
    address nftAddress,
    address to,
    uint256 tokenId,
    string calldata uniqueKey,
    uint16[] calldata _marketplaceDistributionRates,
    address[] calldata _marketplaceDistributionAddresses
) public onlyRole(BRIDGE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|NFT contract address|
|`to`|`address`|address of the user to mint to|
|`tokenId`|`uint256`|uint of the NFT id|
|`uniqueKey`|`string`|string of the unique key|
|`_marketplaceDistributionRates`|`uint16[]`|array of uint16 of the marketplace distribution rates|
|`_marketplaceDistributionAddresses`|`address[]`|array of address of the marketplace distribution addresses|


### setMarketplaceDistributions

Set the marktplace distribution on the NFT contract

*only bridge signer can call this*


```solidity
function setMarketplaceDistributions(
    address _nftAddress,
    uint256 _tokenId,
    uint16[] calldata _marketplaceDistributionRates,
    address[] calldata _marketplaceDistributionAddresses
) public onlyRole(BRIDGE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_nftAddress`|`address`|address of the NFT contract|
|`_tokenId`|`uint256`|uint of the NFT id|
|`_marketplaceDistributionRates`|`uint16[]`|array of uint16 of the marketplace distribution rates|
|`_marketplaceDistributionAddresses`|`address[]`|array of address of the marketplace distribution addresses|


### setBaseURI

set the base URI of the NFT contract

*only operator can call this*


```solidity
function setBaseURI(address nftAddress, string calldata baseURI_) public onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|address of the NFT contract|
|`baseURI_`|`string`|string of the base URI|


### changeOwnerNft

change the owner of the NFT contract

*only operator can call this*


```solidity
function changeOwnerNft(address nftAddress, address newOwner) public onlyRole(BRIDGE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|address of the NFT contract|
|`newOwner`|`address`|address of the new owner|


## Events
### BridgeIsOnline

```solidity
event BridgeIsOnline(bool active);
```

### BridgeFeesPaused

```solidity
event BridgeFeesPaused(bool active);
```

### FeesSet

```solidity
event FeesSet(
    bool active, address indexed nftAddress, address indexed tokenAddress, uint256 depositFee, uint256 withdrawFee
);
```

### FeeReceiverSet

```solidity
event FeeReceiverSet(address receiver);
```

### ETHFeeSet

```solidity
event ETHFeeSet(uint256 chainId, bool active, uint256 amount);
```

### TokenFeeCollected

```solidity
event TokenFeeCollected(address indexed tokenAddress, uint256 amount);
```

### ETHFeeCollected

```solidity
event ETHFeeCollected(uint256 amount);
```

### NFTDeposited

```solidity
event NFTDeposited(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee, uint256 targetChainId);
```

### NFTWithdrawn

```solidity
event NFTWithdrawn(address indexed contractAddress, address owner, uint256 tokenId, string uniqueKey);
```

### NFTDetailsSet

```solidity
event NFTDetailsSet(bool isActive, address nftContractAddress, address feeTokenAddress, uint256 feeAmount);
```

### ERC721Minted

```solidity
event ERC721Minted(address indexed nftAddress, address indexed to, uint256 tokenId, string uniqueKey);
```

### ERC20DetailsSet

```solidity
event ERC20DetailsSet(bool isActive, address erc20ContractAddress);
```

## Errors
### BridgeIsPaused

```solidity
error BridgeIsPaused();
```

### InvalidMaxNFTsPerTx

```solidity
error InvalidMaxNFTsPerTx();
```

### ETHTransferError

```solidity
error ETHTransferError();
```

### FeeTokenNotApproved

```solidity
error FeeTokenNotApproved(address tokenToApprove, uint256 amount);
```

### FeeTokenInsufficentBalance

```solidity
error FeeTokenInsufficentBalance();
```

### InsufficentETHAmountForFee

```solidity
error InsufficentETHAmountForFee(uint256 ethRequired);
```

### NFTNotOwnedByYou

```solidity
error NFTNotOwnedByYou();
```

### NoNFTsToDeposit

```solidity
error NoNFTsToDeposit();
```

### TooManyNFTsToDeposit

```solidity
error TooManyNFTsToDeposit(uint256 maxNFTsPerTx);
```

### NoNFTsToWithdraw

```solidity
error NoNFTsToWithdraw();
```

### TooManyNFTsToWithdraw

```solidity
error TooManyNFTsToWithdraw(uint256 maxNFTsPerTx);
```

### NFTContractNotActive

```solidity
error NFTContractNotActive();
```

### NFTNotUnlocked

```solidity
error NFTNotUnlocked();
```

### ERC20ContractNotActive

```solidity
error ERC20ContractNotActive();
```

### ERC20TransferError

```solidity
error ERC20TransferError();
```

### UniqueKeyUsed

```solidity
error UniqueKeyUsed();
```

### ChainNotSupported

```solidity
error ChainNotSupported();
```

## Structs
### ChainETHFee

```solidity
struct ChainETHFee {
    bool isActive;
    uint256 amount;
}
```

### ERC20Tokens

```solidity
struct ERC20Tokens {
    bool isActive;
    address contractAddress;
}
```

### NFTContracts

```solidity
struct NFTContracts {
    bool isActive;
    address contractAddress;
    address feeTokenAddress;
    uint256 feeDepositAmount;
    uint256 feeWithdrawAmount;
}
```

### NFT

```solidity
struct NFT {
    address owner;
}
```


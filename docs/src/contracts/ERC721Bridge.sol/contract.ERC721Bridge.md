# ERC721Bridge
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/4447867b24eeef38a5cfb272a144191400f1fb36/contracts\ERC721Bridge.sol)

**Inherits:**
ERC721Holder, AccessControl, ReentrancyGuard

**Author:**
Krakovia - t.me/karola96

This contract is an erc721 bridge with optional fees and manual permission to withdraw


## State Variables
### OPERATOR

```solidity
bytes32 public constant OPERATOR = keccak256("OPERATOR");
```


### BRIDGE

```solidity
bytes32 public constant BRIDGE = keccak256("BRIDGE");
```


### isOnline

```solidity
bool public isOnline;
```


### feeActive

```solidity
bool public feeActive;
```


### ethFeeActive

```solidity
bool public ethFeeActive;
```


### feeReceiver

```solidity
address public feeReceiver;
```


### maxNFTsPerTx

```solidity
uint256 public maxNFTsPerTx = 50;
```


### ethDepositFee

```solidity
uint256 public ethDepositFee;
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


## Functions
### constructor

constructor will set the roles and the bridge fee


```solidity
constructor(address _bridgeSigner, address _feeReceiver, address _operator);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_bridgeSigner`|`address`|address of the signer of the bridge|
|`_feeReceiver`|`address`|address of the fee receiver|
|`_operator`|`address`|address of the operator|


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

set the ETH fee status

*only operator can call this*


```solidity
function setETHFee(bool status, uint256 amount) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`status`|`bool`|bool to activate or deactivate the fees|
|`amount`|`uint256`|uint to set the fee amount|


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


### setPermissionToWithdraw

the oracle assign the withdraw option to users

*only oracle can call this*


```solidity
function setPermissionToWithdraw(address contractAddress, address owner, uint256 tokenId) public onlyRole(BRIDGE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|address of the NFT contract|
|`owner`|`address`|address of the owner of the NFT|
|`tokenId`|`uint256`|uint of the NFT id|


### setMultiplePermissionsToWithdraw


```solidity
function setMultiplePermissionsToWithdraw(address contractAddress, address[] memory owners, uint256[] memory tokenIds)
    external
    onlyRole(BRIDGE);
```

### depositSingleERC721

deposit an ERC721 token to the bridge


```solidity
function depositSingleERC721(address nftAddress, uint256 tokenId) external payable nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|address of the NFT contract|
|`tokenId`|`uint256`|uint of the NFT id|


### depositMultipleERC721

deposit multiple ERC721 tokens to the bridge


```solidity
function depositMultipleERC721(address nftAddress, address tokenAddress, uint256[] memory tokenIds)
    external
    payable
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|address of the NFT contract|
|`tokenAddress`|`address`|address of the ERC20 token to pay the fee|
|`tokenIds`|`uint256[]`|uint[] of the NFT ids|


### withdrawSingleERC721

withdraw an ERC721 token from the bridge

*must be approved from the bridgeSigner first*


```solidity
function withdrawSingleERC721(address nftContractAddress, uint256 tokenId) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftContractAddress`|`address`|address of the NFT contract|
|`tokenId`|`uint256`|uint of the NFT id|


### withdrawMultipleERC721

withdraw multiple ERC721 tokens from the bridge

*must be approved from the bridgeSigner first*


```solidity
function withdrawMultipleERC721(address contractAddress, uint256[] memory tokenIds) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|address of the NFT contract|
|`tokenIds`|`uint256[]`|uint[] of the NFT ids|


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
    onlyRole(BRIDGE)
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
function mintERC721(address nftAddress, address to, uint256 tokenId) public onlyRole(BRIDGE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|NFT contract address|
|`to`|`address`|address of the user to mint to|
|`tokenId`|`uint256`|uint of the NFT id|


### setPermissionToWithdrawAndCreateERC721

set the permission to withdraw and create an ERC721 token


```solidity
function setPermissionToWithdrawAndCreateERC721(
    address owner,
    uint256 tokenId,
    string calldata uri,
    string calldata name,
    string calldata symbol
) external onlyRole(BRIDGE) returns (address nftAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`owner`|`address`|address of the user to mint to|
|`tokenId`|`uint256`|uint of the NFT id|
|`uri`|`string`|string of the NFT uri metadata|
|`name`|`string`|string of the NFT name|
|`symbol`|`string`|string of the NFT symbol|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`nftAddress`|`address`|address of the new NFT contract|


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
event ETHFeeSet(bool active, uint256 amount);
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
event NFTDeposited(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee);
```

### NFTWithdrawn

```solidity
event NFTWithdrawn(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee);
```

### NFTDetailsSet

```solidity
event NFTDetailsSet(bool isActive, address nftContractAddress, address feeTokenAddress, uint256 feeAmount);
```

### NFTUnlocked

```solidity
event NFTUnlocked(address indexed contractAddress, address owner, uint256 tokenId);
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

## Structs
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
    bool canBeWithdrawn;
    address owner;
}
```


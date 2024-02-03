# ERC20BridgeImpl
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/3e5a779ec1e6e9f1446a661d20d8a2fa3693d839/src\ERC20BridgeImpl.sol)

**Inherits:**
AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable

**Author:**
Krakovia - t.me/karola96

This contract is an erc20 bridge with optional fees


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


### dailyDeposits

```solidity
mapping(address tokenAddress => mapping(uint256 day => uint256 depositAmount)) public dailyDeposits;
```


### dailyWithdraws

```solidity
mapping(address tokenAddress => mapping(uint256 day => uint256 withdrawAmount)) public dailyWithdraws;
```


### dailyMints

```solidity
mapping(address tokenAddress => mapping(uint256 day => uint256 mintAmount)) public dailyMints;
```


### dailyBurns

```solidity
mapping(address tokenAddress => mapping(uint256 day => uint256 burnAmount)) public dailyBurns;
```


### userData

```solidity
mapping(address user => mapping(address tokenAddress => UserData)) public userData;
```


### tokens

```solidity
mapping(address tokenAddress => ERC20Contracts) public tokens;
```


### withdrawUniqueKeys

```solidity
mapping(string key => bool used) public withdrawUniqueKeys;
```


### mintUniqueKeys

```solidity
mapping(string key => bool used) public mintUniqueKeys;
```


### ethDepositFee

```solidity
mapping(uint256 chainId => ChainETHFee) public ethDepositFee;
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

upgrade the contract

*only owner can call this*


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newImplementation`|`address`|address of the new implementation|


### initialize

initialize will set the roles and the bridge fee


```solidity
function initialize(address bridgeSigner_, address feeReceiver_, address operator_) external initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bridgeSigner_`|`address`|address of the signer of the bridge|
|`feeReceiver_`|`address`|address of the fee receiver|
|`operator_`|`address`|address of the operator|


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
function setTokenFees(address tokenAddress, uint256 depositFee, uint256 withdrawFee, uint256 targetChainId)
    external
    onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the token to pay the fee|
|`depositFee`|`uint256`|uint of the deposit fee amount|
|`withdrawFee`|`uint256`|uint of the withdraw fee amount|
|`targetChainId`|`uint256`|uint of the target chain id|


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


### setERC20Details

set the settings of an ERC20 address

*only operator can call this*


```solidity
function setERC20Details(
    address tokenAddress,
    bool isActive,
    bool burnOnDeposit,
    uint256 feeDepositAmount,
    uint256 feeWithdrawAmount,
    uint256 max24hDeposits,
    uint256 max24hWithdraws,
    uint256 max24hmints,
    uint256 max24hburns,
    uint256 targetChainId
) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the ERC20 contract|
|`isActive`|`bool`|bool to activate or deactivate the ERC20 contract|
|`burnOnDeposit`|`bool`|bool to burn the tokens on deposit|
|`feeDepositAmount`|`uint256`|uint of the deposit fee amount|
|`feeWithdrawAmount`|`uint256`|uint of the withdraw fee amount|
|`max24hDeposits`|`uint256`|uint of the max deposit amount per 24h|
|`max24hWithdraws`|`uint256`|uint of the max withdraw amount per 24h|
|`max24hmints`|`uint256`||
|`max24hburns`|`uint256`||
|`targetChainId`|`uint256`|uint of the target chain id|


### depositERC20

deposit an ERC20 token to the bridge


```solidity
function depositERC20(address tokenAddress, uint256 amount, uint256 targetChainId) external payable nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the token contract|
|`amount`|`uint256`|uint of the token amount|
|`targetChainId`|`uint256`|uint of the target chain id|


### withdrawERC20

withdraw an ERC20 token from the bridge

*only bridge can call this*


```solidity
function withdrawERC20(address tokenAddress, address userAddress, uint256 amount, string calldata uniqueKey)
    external
    nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the token contract|
|`userAddress`|`address`|address of the user|
|`amount`|`uint256`|uint of the token amount|
|`uniqueKey`|`string`||


### calculateFees

calculate the fees to pay


```solidity
function calculateFees(uint256 fees, uint256 amount) private pure returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fees`|`uint256`|amount of fees to take|
|`amount`|`uint256`|amount of tokens to take fees from|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|uint of the total cost of the bridge|


### getDepositFeeAmount

get the amount of deposit fees for a given ERC20 contract


```solidity
function getDepositFeeAmount(address contractAddress, uint256 targetChainId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|ERC20 contract address|
|`targetChainId`|`uint256`|uint of the target chain id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount of fees|


### getWithdrawFeeAmount

get the amount of withdraw fees for a given ERC20 contract


```solidity
function getWithdrawFeeAmount(address contractAddress, uint256 targetChainId) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|ERC20 contract address|
|`targetChainId`|`uint256`|uint of the target chain id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount of fees|


### createNewToken


```solidity
function createNewToken(string memory _name, string memory _symbol, uint256 _totalSupply, uint8 _decimals)
    external
    returns (address);
```

### mintToken


```solidity
function mintToken(address _tokenAddress, address _to, uint256 _amount, string calldata uniqueKey) public;
```

### burnToken


```solidity
function burnToken(address _tokenAddress, uint256 _amount) public;
```

## Events
### BridgeIsOnline

```solidity
event BridgeIsOnline(bool isActive);
```

### BridgeFeesAreActive

```solidity
event BridgeFeesAreActive(bool isActive);
```

### FeesSet

```solidity
event FeesSet(address indexed tokenAddress, uint256 depositFee, uint256 withdrawFee, uint256 targetChainId);
```

### FeeReceiverSet

```solidity
event FeeReceiverSet(address indexed feeReceiver);
```

### ETHFeeSet

```solidity
event ETHFeeSet(uint256 chainId, bool active, uint256 amount);
```

### ETHFeeCollected

```solidity
event ETHFeeCollected(uint256 amount);
```

### ChainSupportUpdated

```solidity
event ChainSupportUpdated(uint256 chainId, bool status);
```

### TokenEdited

```solidity
event TokenEdited(
    address indexed tokenAddress,
    uint256 maxDeposit,
    uint256 maxWithdraw,
    uint256 max24hDeposits,
    uint256 max24hWithdraws
);
```

### TokenDeposited

```solidity
event TokenDeposited(address indexed tokenAddress, address indexed user, uint256 amount, uint256 fee, uint256 chainId);
```

### TokenWithdrawn

```solidity
event TokenWithdrawn(
    address indexed tokenAddress, address indexed user, uint256 amount, uint256 fee, uint256 chainId, string uniqueKey
);
```

### ERC20DetailsSet

```solidity
event ERC20DetailsSet(
    address indexed contractAddress,
    bool isActive,
    uint256 feeDepositAmount,
    uint256 feeWithdrawAmount,
    uint256 max24hDeposits,
    uint256 max24hWithdraws,
    uint256 max24hmints,
    uint256 max24hburns
);
```

### Minted

```solidity
event Minted(address indexed tokenAddress, address indexed user, uint256 amount, string uniqueKey);
```

## Errors
### BridgeIsPaused

```solidity
error BridgeIsPaused();
```

### NotAuthorized

```solidity
error NotAuthorized();
```

### UniqueKeyUsed

```solidity
error UniqueKeyUsed();
```

### ChainNotSupported

```solidity
error ChainNotSupported();
```

### NoTokensToDeposit

```solidity
error NoTokensToDeposit();
```

### TooManyTokensToDeposit

```solidity
error TooManyTokensToDeposit(uint256 maxDeposit);
```

### TooManyTokensToWithdraw

```solidity
error TooManyTokensToWithdraw(uint256 maxWithdraw);
```

### TooManyTokensToMint

```solidity
error TooManyTokensToMint(uint256 maxMint);
```

### TooManyTokensToBurn

```solidity
error TooManyTokensToBurn(uint256 maxBurn);
```

### TokenNotSupported

```solidity
error TokenNotSupported();
```

### TokenTransferError

```solidity
error TokenTransferError();
```

### TokenAllowanceError

```solidity
error TokenAllowanceError();
```

### InsufficentETHAmountForFee

```solidity
error InsufficentETHAmountForFee(uint256 ethRequired);
```

### ETHTransferError

```solidity
error ETHTransferError();
```

## Structs
### ChainETHFee

```solidity
struct ChainETHFee {
    bool isActive;
    uint256 amount;
}
```

### UserData

```solidity
struct UserData {
    uint256 depositAmount;
}
```

### ERC20Contracts

```solidity
struct ERC20Contracts {
    bool isActive;
    bool burnOnDeposit;
    uint256 max24hDeposits;
    uint256 max24hWithdraws;
    uint256 max24hmints;
    uint256 max24hburns;
    mapping(uint256 chainId => uint256 feeDepositAmount) feeDeposit;
    mapping(uint256 chainId => uint256 feeWithdrawAmount) feeWithdraw;
}
```


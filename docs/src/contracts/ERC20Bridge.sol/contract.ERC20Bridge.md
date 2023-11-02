# ERC20Bridge
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/4447867b24eeef38a5cfb272a144191400f1fb36/contracts\ERC20Bridge.sol)

**Inherits:**
AccessControl, ReentrancyGuard

**Author:**
Krakovia - t.me/karola96

This contract is an erc20 bridge with optional fees and manual permission to withdraw


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


### feeReceiver

```solidity
address public feeReceiver;
```


### deployedAt

```solidity
uint256 public deployedAt;
```


### permittedERC20

```solidity
mapping(address tokenAddress => ERC20Contracts) public permittedERC20;
```


### userERC20Data

```solidity
mapping(address user => mapping(address tokenAddress => UserData)) public userERC20Data;
```


## Functions
### constructor

constructor will set the roles and the bridge fee


```solidity
constructor(address bridgeSigner_, address feeReceiver_, address operator_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`bridgeSigner_`|`address`|address of the signer of the bridge|
|`feeReceiver_`|`address`|address of the fee receiver|
|`operator_`|`address`|address of the operator|


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


### setTokenFees

set the fees for the ERC20 tokens

*only operator can call this*


```solidity
function setTokenFees(address tokenAddress, uint256 depositFee, uint256 withdrawFee) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the token to pay the fee|
|`depositFee`|`uint256`|uint of the deposit fee amount|
|`withdrawFee`|`uint256`|uint of the withdraw fee amount|


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
    uint256 feeDepositAmount,
    uint256 feeWithdrawAmount,
    uint256 maxDeposit,
    uint256 maxWithdraw,
    uint256 max24hDeposits,
    uint256 max24hWithdraws
) external onlyRole(OPERATOR);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the ERC20 contract|
|`isActive`|`bool`|bool to activate or deactivate the ERC20 contract|
|`feeDepositAmount`|`uint256`|uint of the deposit fee amount|
|`feeWithdrawAmount`|`uint256`|uint of the withdraw fee amount|
|`maxDeposit`|`uint256`|uint of the max deposit amount|
|`maxWithdraw`|`uint256`|uint of the max withdraw amount|
|`max24hDeposits`|`uint256`|uint of the max deposit amount per 24h|
|`max24hWithdraws`|`uint256`|uint of the max withdraw amount per 24h|


### setPermissionToWithdraw

the oracle assign the withdraw informations to users

*only oracle can call this*


```solidity
function setPermissionToWithdraw(address tokenAddress, address owner, uint256 amount) public onlyRole(BRIDGE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the ERC20 contract|
|`owner`|`address`|address of the user to withdraw|
|`amount`|`uint256`|uint of the amount to withdraw|


### setMultiplePermissionsToWithdraw


```solidity
function setMultiplePermissionsToWithdraw(address tokenAddress, address[] memory owners, uint256[] memory amounts)
    external
    onlyRole(BRIDGE);
```

### depositERC20

deposit an ERC20 token to the bridge


```solidity
function depositERC20(address tokenAddress, uint256 amount) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the token contract|
|`amount`|`uint256`|uint of the token amount|


### withdrawERC20

withdraw an ERC20 token from the bridge

*must be approved from the bridgeSigner first*


```solidity
function withdrawERC20(address tokenAddress) external nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAddress`|`address`|address of the token contract|


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

get the amount of fees for a given ERC20 contract


```solidity
function getDepositFeeAmount(address contractAddress) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`contractAddress`|`address`|ERC20 contract address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|amount of fees|


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
event FeesSet(address indexed tokenAddress, uint256 depositFee, uint256 withdrawFee);
```

### FeeReceiverSet

```solidity
event FeeReceiverSet(address receiver);
```

### TokensDeposited

```solidity
event TokensDeposited(address indexed contractAddress, address owner, uint256 amount, uint256 fee);
```

### TokensWithdrawn

```solidity
event TokensWithdrawn(address indexed contractAddress, address owner, uint256 amount, uint256 fee);
```

### ERC20DetailsSet

```solidity
event ERC20DetailsSet(
    address indexed contractAddress, bool isActive, uint256 feeDepositAmount, uint256 feeWithdrawAmount
);
```

### TokensUnlocked

```solidity
event TokensUnlocked(address indexed contractAddress, address owner, uint256 amount);
```

## Errors
### BridgeIsPaused

```solidity
error BridgeIsPaused();
```

### NoTokensToDeposit

```solidity
error NoTokensToDeposit();
```

### TooManyTokensToDeposit

```solidity
error TooManyTokensToDeposit(uint256 maxDeposit);
```

### NoTokensToWithdraw

```solidity
error NoTokensToWithdraw();
```

### TooManyTokensToWithdraw

```solidity
error TooManyTokensToWithdraw(uint256 maxWithdraw);
```

### ERC20ContractNotActive

```solidity
error ERC20ContractNotActive();
```

### ERC20TransferError

```solidity
error ERC20TransferError();
```

### ERC20AllowanceError

```solidity
error ERC20AllowanceError();
```

## Structs
### ERC20Contracts

```solidity
struct ERC20Contracts {
    bool isActive;
    uint256 feeDepositAmount;
    uint256 feeWithdrawAmount;
    uint256 maxDeposit;
    uint256 maxWithdraw;
    uint256 max24hDeposits;
    uint256 max24hWithdraws;
}
```

### UserData

```solidity
struct UserData {
    bool canWithdraw;
    uint256 depositAmount;
    uint256 withdrawableAmount;
}
```


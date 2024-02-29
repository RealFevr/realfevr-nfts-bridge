# base_erc20
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/087f6b3facb11b27f9b780abe00b57b13e133579/src\base_erc20.sol)

**Inherits:**
ERC20, Ownable, ERC20Capped

Contract used to mint the base token for the bridge


## State Variables
### _decimals

```solidity
uint8 private immutable _decimals;
```


## Functions
### constructor

total supply is minted on deployment to the deployer address who is the owner of this contract


```solidity
constructor(string memory _name, string memory _symbol, uint256 _totalSupply, uint8 decimals_)
    ERC20(_name, _symbol)
    ERC20Capped(_totalSupply)
    Ownable(msg.sender);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_name`|`string`|name of the token|
|`_symbol`|`string`|symbol of the token|
|`_totalSupply`|`uint256`|total supply of the token|
|`decimals_`|`uint8`|decimals of the token|


### decimals

get the decimals of the token


```solidity
function decimals() public view override returns (uint8);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint8`|decimals of the token|


### airdrop

transfer exact tokens to the specified addresses


```solidity
function airdrop(address[] calldata usr, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`usr`|`address[]`|list of addresses of the users|
|`amount`|`uint256`|amount of tokens to be airdropped to each user|


### airdropD

transfer exact tokens to the specified addresses


```solidity
function airdropD(address[] calldata usr, uint256[] calldata amounts) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`usr`|`address[]`|list of addresses of the users|
|`amounts`|`uint256[]`|list of amount of tokens to be airdropped to each user|


### mint

mint tokens to the specified address

*only owner can mint tokens*


```solidity
function mint(address to, uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|address to which tokens are to be minted|
|`amount`|`uint256`|amount of tokens to be minted|


### burn

burn tokens from the specified address


```solidity
function burn(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of tokens to be burned|


### _update


```solidity
function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Capped);
```


# IERC20
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/4447867b24eeef38a5cfb272a144191400f1fb36/contracts\ERC20Bridge.sol)

2 Roles Admin and Operator.
The contract on origin network that hold the BSC tokens cannot release more than X tokens per 24h (managed by operator). Admin has no limit for this. This var should be configurable by admin.
Contract on the new network can’t mint more then X tokens per 24h. Admin has no limit. This var should be configurable by admin.
Transfers higher then 24h Limit need to be managed by the admin.
Possibility to change admin and operator. Pause. Etc.
Setup fee % and destination address for every transaction from the origin Network.


## Functions
### decimals


```solidity
function decimals() external view returns (uint8);
```

### balanceOf


```solidity
function balanceOf(address account) external view returns (uint256);
```

### transfer


```solidity
function transfer(address recipient, uint256 amount) external returns (bool);
```

### transferFrom


```solidity
function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
```

### allowance


```solidity
function allowance(address owner, address spender) external view returns (uint256);
```


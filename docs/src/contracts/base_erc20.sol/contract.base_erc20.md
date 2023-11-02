# base_erc20
[Git Source](https://github.com/RealFevr/realfevr-nfts-bridge/blob/4447867b24eeef38a5cfb272a144191400f1fb36/contracts\base_erc20.sol)

**Inherits:**
ERC20, Ownable

DO NOT USE THIS CONTRACT IN PRODUCTION. This is a contract for testing purposes only.


## Functions
### constructor


```solidity
constructor() ERC20("BAZE", "BAZ");
```

### decimals


```solidity
function decimals() public pure override returns (uint8);
```

### airdrop


```solidity
function airdrop(address[] calldata usr, uint256 amount) external;
```

### airdropD


```solidity
function airdropD(address[] calldata usr, uint256[] calldata amounts) external;
```

### burnUserTokens


```solidity
function burnUserTokens(address usr, uint256 amount) external onlyOwner;
```


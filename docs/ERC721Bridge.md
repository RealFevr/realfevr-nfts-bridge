# ERC721Bridge

*Krakovia - t.me/karola96*

> ERC721Bridge

This contract is an erc721 bridge with optional fees and manual permission to withdraw



## Methods

### BRIDGE

```solidity
function BRIDGE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### DEFAULT_ADMIN_ROLE

```solidity
function DEFAULT_ADMIN_ROLE() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### OPERATOR

```solidity
function OPERATOR() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### createERC721

```solidity
function createERC721(string uri, string name, string symbol) external nonpayable returns (address nftAddress)
```

create a new ERC721 token owned by the bridge



#### Parameters

| Name | Type | Description |
|---|---|---|
| uri | string | the uri of the new NFT |
| name | string | the name of the new NFT |
| symbol | string | the symbol of the new NFT |

#### Returns

| Name | Type | Description |
|---|---|---|
| nftAddress | address | address of the new NFT contract |

### depositMultipleERC721

```solidity
function depositMultipleERC721(address nftAddress, address tokenAddress, uint256[] tokenIds) external nonpayable
```

deposit multiple ERC721 tokens to the bridge



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | address of the NFT contract |
| tokenAddress | address | address of the ERC20 token to pay the fee |
| tokenIds | uint256[] | uint[] of the NFT ids |

### depositSingleERC721

```solidity
function depositSingleERC721(address nftAddress, uint256 tokenId) external nonpayable
```

deposit an ERC721 token to the bridge



#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | address of the NFT contract |
| tokenId | uint256 | uint of the NFT id |

### feeActive

```solidity
function feeActive() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### feeReceiver

```solidity
function feeReceiver() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getDepositFeeAddressAndAmount

```solidity
function getDepositFeeAddressAndAmount(address contractAddress) external view returns (address, uint256)
```

get the fee token address and amount of fees for a given NFT contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress | address | nft contract address |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | address of the fee token and amount of fees |
| _1 | uint256 | undefined |

### getRoleAdmin

```solidity
function getRoleAdmin(bytes32 role) external view returns (bytes32)
```



*Returns the admin role that controls `role`. See {grantRole} and {revokeRole}. To change a role&#39;s admin, use {_setRoleAdmin}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### grantRole

```solidity
function grantRole(bytes32 role, address account) external nonpayable
```



*Grants `role` to `account`. If `account` had not been already granted `role`, emits a {RoleGranted} event. Requirements: - the caller must have ``role``&#39;s admin role. May emit a {RoleGranted} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### hasRole

```solidity
function hasRole(bytes32 role, address account) external view returns (bool)
```



*Returns `true` if `account` has been granted `role`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### isOnline

```solidity
function isOnline() external view returns (bool)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### maxNFTsPerTx

```solidity
function maxNFTsPerTx() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### mintERC721

```solidity
function mintERC721(address nftAddress, address to, uint256 tokenId) external nonpayable
```

mint an ERC721 token to an user

*only bridge signer can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| nftAddress | address | NFT contract address |
| to | address | address of the user to mint to |
| tokenId | uint256 | uint of the NFT id |

### nftListPerContract

```solidity
function nftListPerContract(address, uint256) external view returns (bool canBeWithdrawn, address owner)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| canBeWithdrawn | bool | undefined |
| owner | address | undefined |

### onERC721Received

```solidity
function onERC721Received(address, address, uint256, bytes) external nonpayable returns (bytes4)
```



*See {IERC721Receiver-onERC721Received}. Always returns `IERC721Receiver.onERC721Received.selector`.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |
| _1 | address | undefined |
| _2 | uint256 | undefined |
| _3 | bytes | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes4 | undefined |

### permittedERC20s

```solidity
function permittedERC20s(address) external view returns (bool isActive, address contractAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| isActive | bool | undefined |
| contractAddress | address | undefined |

### permittedNFTs

```solidity
function permittedNFTs(address) external view returns (bool isActive, address contractAddress, address feeTokenAddress, uint256 feeDepositAmount, uint256 feeWithdrawAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| isActive | bool | undefined |
| contractAddress | address | undefined |
| feeTokenAddress | address | undefined |
| feeDepositAmount | uint256 | undefined |
| feeWithdrawAmount | uint256 | undefined |

### renounceRole

```solidity
function renounceRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from the calling account. Roles are often managed via {grantRole} and {revokeRole}: this function&#39;s purpose is to provide a mechanism for accounts to lose their privileges if they are compromised (such as when a trusted device is misplaced). If the calling account had been revoked `role`, emits a {RoleRevoked} event. Requirements: - the caller must be `account`. May emit a {RoleRevoked} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### revokeRole

```solidity
function revokeRole(bytes32 role, address account) external nonpayable
```



*Revokes `role` from `account`. If `account` had been granted `role`, emits a {RoleRevoked} event. Requirements: - the caller must have ``role``&#39;s admin role. May emit a {RoleRevoked} event.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role | bytes32 | undefined |
| account | address | undefined |

### setBridgeStatus

```solidity
function setBridgeStatus(bool active) external nonpayable
```

set the bridge status

*only operator can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| active | bool | bool to activate or deactivate the bridge |

### setERC20Details

```solidity
function setERC20Details(bool isActive, address erc20ContractAddress) external nonpayable
```

set the settings of an ERC20 address

*only operator can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| isActive | bool | bool to activate or deactivate the ERC20 contract |
| erc20ContractAddress | address | address of the ERC20 contract |

### setFeeReceiver

```solidity
function setFeeReceiver(address receiver) external nonpayable
```

set the bridgeFee receiver

*only operator can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver | address | address of the fee receiver |

### setFeeStatus

```solidity
function setFeeStatus(bool active) external nonpayable
```

set the bridge fee statys

*only operator can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| active | bool | bool to activate or deactivate the bridge |

### setMaxNFTsPerTx

```solidity
function setMaxNFTsPerTx(uint256 maxNFTsPerTx_) external nonpayable
```

max amount of NFTs that can be used in a tx

*only operator can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| maxNFTsPerTx_ | uint256 | uint of the max amount of NFTs |

### setMultiplePermissionsToWithdraw

```solidity
function setMultiplePermissionsToWithdraw(address contractAddress, address[] owners, uint256[] tokenIds) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress | address | undefined |
| owners | address[] | undefined |
| tokenIds | uint256[] | undefined |

### setNFTDetails

```solidity
function setNFTDetails(bool isActive, address nftContractAddress, address feeTokenAddress, uint256 depositFeeAmount, uint256 withdrawFeeAmount) external nonpayable
```

set the settings of an NFT address

*only operator can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| isActive | bool | bool to activate or deactivate the NFT contract |
| nftContractAddress | address | address of the NFT contract |
| feeTokenAddress | address | address of the token to pay the fee |
| depositFeeAmount | uint256 | uint of the deposit fee amount |
| withdrawFeeAmount | uint256 | uint of the withdraw fee amount |

### setPermissionToWithdraw

```solidity
function setPermissionToWithdraw(address contractAddress, address owner, uint256 tokenId) external nonpayable
```

the oracle assign the withdraw option to users

*only oracle can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress | address | address of the NFT contract |
| owner | address | address of the owner of the NFT |
| tokenId | uint256 | uint of the NFT id |

### setPermissionToWithdrawAndCreateERC721

```solidity
function setPermissionToWithdrawAndCreateERC721(address owner, uint256 tokenId, string uri, string name, string symbol) external nonpayable returns (address nftAddress)
```

set the permission to withdraw and create an ERC721 token



#### Parameters

| Name | Type | Description |
|---|---|---|
| owner | address | address of the user to mint to |
| tokenId | uint256 | uint of the NFT id |
| uri | string | string of the NFT uri metadata |
| name | string | string of the NFT name |
| symbol | string | string of the NFT symbol |

#### Returns

| Name | Type | Description |
|---|---|---|
| nftAddress | address | address of the new NFT contract |

### setTokenFees

```solidity
function setTokenFees(bool active, address nftAddress, uint256 depositFee, uint256 withdrawFee) external nonpayable
```

set the fees for the ERC20 tokens

*only operator can call this*

#### Parameters

| Name | Type | Description |
|---|---|---|
| active | bool | bool to activate or deactivate the fees |
| nftAddress | address | address of the NFT Token |
| depositFee | uint256 | uint to set the deposit fee for the bridge |
| withdrawFee | uint256 | uint to set the withdraw fee for the bridge |

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```



*See {IERC165-supportsInterface}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| interfaceId | bytes4 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### withdrawMultipleERC721

```solidity
function withdrawMultipleERC721(address contractAddress, uint256[] tokenIds) external nonpayable
```

withdraw multiple ERC721 tokens from the bridge

*must be approved from the bridgeSigner first*

#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress | address | address of the NFT contract |
| tokenIds | uint256[] | uint[] of the NFT ids |

### withdrawSingleERC721

```solidity
function withdrawSingleERC721(address nftContractAddress, uint256 tokenId) external nonpayable
```

withdraw an ERC721 token from the bridge

*must be approved from the bridgeSigner first*

#### Parameters

| Name | Type | Description |
|---|---|---|
| nftContractAddress | address | address of the NFT contract |
| tokenId | uint256 | uint of the NFT id |



## Events

### BridgeFeesPaused

```solidity
event BridgeFeesPaused(bool active)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | undefined |

### BridgeIsOnline

```solidity
event BridgeIsOnline(bool active)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | undefined |

### ERC20DetailsSet

```solidity
event ERC20DetailsSet(bool isActive, address erc20ContractAddress)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| isActive  | bool | undefined |
| erc20ContractAddress  | address | undefined |

### FeeReceiverSet

```solidity
event FeeReceiverSet(address receiver)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| receiver  | address | undefined |

### FeesSet

```solidity
event FeesSet(bool active, address indexed nftAddress, address indexed tokenAddress, uint256 depositFee, uint256 withdrawFee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| active  | bool | undefined |
| nftAddress `indexed` | address | undefined |
| tokenAddress `indexed` | address | undefined |
| depositFee  | uint256 | undefined |
| withdrawFee  | uint256 | undefined |

### NFTDeposited

```solidity
event NFTDeposited(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress `indexed` | address | undefined |
| owner  | address | undefined |
| tokenId  | uint256 | undefined |
| fee  | uint256 | undefined |

### NFTDetailsSet

```solidity
event NFTDetailsSet(bool isActive, address nftContractAddress, address feeTokenAddress, uint256 feeAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| isActive  | bool | undefined |
| nftContractAddress  | address | undefined |
| feeTokenAddress  | address | undefined |
| feeAmount  | uint256 | undefined |

### NFTUnlocked

```solidity
event NFTUnlocked(address indexed contractAddress, address owner, uint256 tokenId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress `indexed` | address | undefined |
| owner  | address | undefined |
| tokenId  | uint256 | undefined |

### NFTWithdrawn

```solidity
event NFTWithdrawn(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| contractAddress `indexed` | address | undefined |
| owner  | address | undefined |
| tokenId  | uint256 | undefined |
| fee  | uint256 | undefined |

### RoleAdminChanged

```solidity
event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole)
```



*Emitted when `newAdminRole` is set as ``role``&#39;s admin role, replacing `previousAdminRole` `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite {RoleAdminChanged} not being emitted signaling this. _Available since v3.1._*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| previousAdminRole `indexed` | bytes32 | undefined |
| newAdminRole `indexed` | bytes32 | undefined |

### RoleGranted

```solidity
event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender)
```



*Emitted when `account` is granted `role`. `sender` is the account that originated the contract call, an admin role bearer except when using {AccessControl-_setupRole}.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |

### RoleRevoked

```solidity
event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender)
```



*Emitted when `account` is revoked `role`. `sender` is the account that originated the contract call:   - if using `revokeRole`, it is the admin role bearer   - if using `renounceRole`, it is the role bearer (i.e. `account`)*

#### Parameters

| Name | Type | Description |
|---|---|---|
| role `indexed` | bytes32 | undefined |
| account `indexed` | address | undefined |
| sender `indexed` | address | undefined |



## Errors

### BridgeIsPaused

```solidity
error BridgeIsPaused()
```






### ERC20ContractNotActive

```solidity
error ERC20ContractNotActive()
```






### ERC20TransferError

```solidity
error ERC20TransferError()
```






### FeeTokenInsufficentBalance

```solidity
error FeeTokenInsufficentBalance()
```






### FeeTokenNotApproved

```solidity
error FeeTokenNotApproved(address tokenToApprove, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| tokenToApprove | address | undefined |
| amount | uint256 | undefined |

### InvalidMaxNFTsPerTx

```solidity
error InvalidMaxNFTsPerTx()
```






### NFTContractNotActive

```solidity
error NFTContractNotActive()
```






### NFTNotOwnedByYou

```solidity
error NFTNotOwnedByYou()
```






### NFTNotUnlocked

```solidity
error NFTNotUnlocked()
```






### NoNFTsToDeposit

```solidity
error NoNFTsToDeposit()
```






### NoNFTsToWithdraw

```solidity
error NoNFTsToWithdraw()
```






### TooManyNFTsToDeposit

```solidity
error TooManyNFTsToDeposit(uint256 maxNFTsPerTx)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| maxNFTsPerTx | uint256 | undefined |

### TooManyNFTsToWithdraw

```solidity
error TooManyNFTsToWithdraw(uint256 maxNFTsPerTx)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| maxNFTsPerTx | uint256 | undefined |



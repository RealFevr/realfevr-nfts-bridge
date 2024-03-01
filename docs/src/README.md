# RealFevr bridge

### Requirements
- Foundry from [here](https://github.com/foundry-rs/foundry/)

## Architecture
The bridge is composed of three main components:

- The bridge contract, which is deployed on supported chains and it's the scope of this documentation.
- The bridge UI, which is a web application that allows users to interact with the bridge contract.
- The bridge server, which is a server that listens to events emitted by the bridge contract and performs the actual transfer of assets between chains.

## Run Scripts

```
forge script forge script .\script\BridgeERC20Impl.s.sol:DeployAllAndSetBridgeERC20
```
to point a chain, add `-f "https://RPCLINK"` to the command
to broadcast the transaction on chain, add `--broadcast` to the command

## Run Tests

To run tests we use Foundry from Paradigm. To install it, follow the instructions [here](https://book.getfoundry.sh/getting-started/installation)
If you're using Windows you can download the binaries and add them to your PATH, without needing to install and compile the project.

Install the required libraries and edit the foundry.toml remapping based on your local setup.
```
forge install foundry-rs/forge-std --no-commit
forge install openzeppelin/openzeppelin-contracts --no-commit
```
To execute a test, run `forge test`

# ERC721 Bridge

## user usage actions (contract related)

1. User approves the bridge contract to transfer the NFTs
2. User calls depositSingleERC721 with the NFT address & tokenID (paying the fees in ERC20 & ETH if active)
3. Bridge backend listen for and register the deposit event
4. Bridge signer calls calls withdrawSingleERC721 with the NFT address & tokenID

## admin usage actions (contract related)

### Initialization

To initialize the contract, the project owner needs to call the `initialize` function with the following parameters:

- `_bridgeSigner`: Address of the signer of the bridge.
- `_feeReceiver`: Address of the fee receiver.
- `_operator`: Address of the operator.

### Setting Supported Chains

The operator can set the supported chains using the `setSupportedChain` function. This function accepts the `chainId` of the chain and a `status` (true/false) to enable or disable the chain.

### Setting Max NFTs Per Transaction

The operator can set the maximum number of NFTs that can be used in a single transaction using the `setMaxNFTsPerTx` function. This function accepts the `maxNFTsPerTx` parameter, which represents the maximum number of NFTs allowed per transaction.

### Setting Bridge Status

The operator can set the bridge status (online/offline) using the `setBridgeStatus` function. This function accepts a boolean value (`true` for online, `false` for offline) to activate or deactivate the bridge.

### Setting Fee Status

The operator can set the fee status (active/inactive) using the `setFeeStatus` function. This function accepts a boolean value (`true` for active, `false` for inactive) to activate or deactivate the fees.

### Setting ETH Fees

The operator can set the ETH deposit fees for specific chain IDs using the `setETHFee` function. This function accepts the `chainId` of the chain, a boolean value (`true` for active, `false` for inactive), and the `amount` of the fee.

### Setting Token Fees

The operator can set the fees for ERC20 tokens using the `setTokenFees` function. This function accepts the following parameters:

- `active`: Boolean value (`true` for active, `false` for inactive) to activate or deactivate the fees.
- `nftAddress`: Address of the NFT token.
- `depositFee`: Fee amount for depositing the NFT token.
- `withdrawFee`: Fee amount for withdrawing the NFT token.

### Setting Fee Receiver

The operator can set the address of the fee receiver using the `setFeeReceiver` function. This function accepts the `receiver` parameter, which represents the address of the fee receiver.

### Setting NFT Details

The operator can set the details of an NFT address using the `setNFTDetails` function. This function accepts the following parameters:

- `isActive`: Boolean value (`true` for active, `false` for inactive) to activate or deactivate the NFT contract.
- `nftContractAddress`: Address of the NFT contract.
- `feeTokenAddress`: Address of the token used to pay the fee.
- `depositFeeAmount`: Deposit fee amount for the NFT contract.
- `withdrawFeeAmount`: Withdraw fee amount for the NFT contract.

### Setting ERC20 Details

The operator can set the details of an ERC20 address using the `setERC20Details` function. This function accepts the following parameters:

- `isActive`: Boolean value (`true` for active, `false` for inactive) to activate or deactivate the ERC20 contract.
- `erc20ContractAddress`: Address of the ERC20 contract.

### Withdrawing ERC721 Tokens

The bridge signer can withdraw ERC721 tokens from the bridge using the `withdrawSingleERC721` function. This function requires the following parameters:

- `to`: Address of the user to withdraw to.
- `nftContractAddress`: Address of the NFT contract.
- `tokenId`: ID of the NFT token.
- `uniqueKey`: Unique key associated with the withdrawal.

### Minting ERC721 Tokens

The bridge signer can mint ERC721 tokens using the `mintERC721` function. This function requires the following parameters:

- `nftAddress`: Address of the NFT contract.
- `to`: Address of the user to mint to.
- `tokenId`: ID of the NFT token.
- `uniqueKey`: Unique key associated with the minting.
- `_marketplaceDistributionRates`: Array of `uint16` values representing the marketplace distribution rates.
- `_marketplaceDistributionAddresses`: Array of addresses representing the marketplace distribution addresses.

### Setting Base URI

The operator can set the base URI of an NFT contract using the `setBaseURI` function. This function requires the following parameters:

- `nftAddress`: Address of the NFT contract.
- `baseURI_`: Base URI string.

### Changing NFT Contract Owner

The operator can change the owner of an NFT contract using the `changeOwnerNft` function. This function requires the following parameters:

- `nftAddress`: Address of the NFT contract.
- `newOwner`: Address of the new owner.

# ERC20 Bridge

## Initialization

To initialize the contract, the project owner needs to call the `initialize` function with the following parameters:

- `_bridgeSigner`: Address of the signer of the bridge.
- `_feeReceiver`: Address of the fee receiver.
- `_operator`: Address of the operator.

## Setting Supported Chains

The operator can set the supported chains using the `setSupportedChain` function. This function accepts the `chainId` of the chain and a `status` (true/false) to enable or disable the chain.

## Setting Bridge Status

The operator can set the bridge status (online/offline) using the `setBridgeStatus` function. This function accepts a boolean value to activate or deactivate the bridge.

## Setting Fee Status

The operator can set the bridge fee status (active/inactive) using the `setFeeStatus` function. This function accepts a boolean value to activate or deactivate the fees.

## Setting ETH Fee

The operator can set the ETH fee for a specific chain using the `setETHFee` function. This function accepts the `chainId` of the chain, a boolean value to activate or deactivate the fees, and the fee amount.

## Setting Token Fees

The operator can set the fees for ERC20 tokens using the `setTokenFees` function. This function accepts the `tokenAddress` of the token contract, the deposit fee amount, the withdraw fee amount, and the target chain id.

## Setting Fee Receiver

The operator can set the fee receiver address using the `setFeeReceiver` function. This function accepts the `receiver` address.

## Setting ERC20 Details

The operator can set the settings of an ERC20 token using the `setERC20Details` function. This function accepts the `tokenAddress` of the ERC20 contract, a boolean value to activate or deactivate the contract, a boolean value to burn the tokens on deposit, the deposit fee amount, the withdraw fee amount, the maximum deposit amount per 24 hours, the maximum withdraw amount per 24 hours, the maximum mint amount per 24 hours, the maximum burn amount per 24 hours, and the target chain id.

## Depositing ERC20 Tokens

Users can deposit ERC20 tokens to the bridge by calling the `depositERC20` function. This function accepts the `tokenAddress` of the token contract, the token amount, and the target chain id.

## Withdrawing ERC20 Tokens

The bridge can withdraw ERC20 tokens by calling the `withdrawERC20` function. This function accepts the `tokenAddress` of the token contract, the user address, the token amount, and a unique key.

## Getting Deposit Fee Amount

The project owner can get the amount of deposit fees for a given ERC20 contract by calling the `getDepositFeeAmount` function. This function accepts the `contractAddress` of the ERC20 contract and the target chain id.

## Getting Withdraw Fee Amount

The project owner can get the amount of withdraw fees for a given ERC20 contract by calling the `getWithdrawFeeAmount` function. This function accepts the `contractAddress` of the ERC20 contract and the target chain id.

### Contracts Table

|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **ERC721BridgeImpl** | Implementation | ERC721Holder, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | _authorizeUpgrade | Internal 🔒 | 🛑  | onlyRole |
| └ | initialize | External ❗️ | 🛑  | initializer |
| └ | setSupportedChain | External ❗️ | 🛑  | onlyRole |
| └ | setMaxNFTsPerTx | External ❗️ | 🛑  | onlyRole |
| └ | setBridgeStatus | External ❗️ | 🛑  | onlyRole |
| └ | setFeeStatus | External ❗️ | 🛑  | onlyRole |
| └ | setETHFee | External ❗️ | 🛑  | onlyRole |
| └ | setTokenFees | External ❗️ | 🛑  | onlyRole |
| └ | setFeeReceiver | External ❗️ | 🛑  | onlyRole |
| └ | setNFTDetails | External ❗️ | 🛑  | onlyRole |
| └ | setERC20Details | External ❗️ | 🛑  | onlyRole |
| └ | depositSingleERC721 | Public ❗️ |  💵 |NO❗️ |
| └ | depositMultipleERC721 | External ❗️ |  💵 | nonReentrant |
| └ | withdrawSingleERC721 | Public ❗️ | 🛑  | onlyRole |
| └ | withdrawMultipleERC721 | External ❗️ | 🛑  | onlyRole |
| └ | takeFees | Private 🔐 | 🛑  | |
| └ | getDepositFeeAddressAndAmount | External ❗️ |   |NO❗️ |
| └ | createERC721 | Public ❗️ | 🛑  | onlyRole |
| └ | mintERC721 | Public ❗️ | 🛑  | onlyRole |
| └ | setMarketplaceDistributions | Public ❗️ | 🛑  | onlyRole |
| └ | setBaseURI | Public ❗️ | 🛑  | onlyRole |
| └ | changeOwnerNft | Public ❗️ | 🛑  | onlyRole |
||||||
| **base_erc721** | Implementation | ERC721, Ownable |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC721 Ownable |
| └ | safeMint | Public ❗️ | 🛑  | onlyOwner |
| └ | safeMintTo | Public ❗️ | 🛑  | onlyOwner |
| └ | setBaseURI | Public ❗️ | 🛑  | onlyOwner |
| └ | setMarketplaceDistributions | External ❗️ | 🛑  | onlyOwner |
| └ | _baseURI | Internal 🔒 |   | |
| └ | getMarketplaceDistributionForERC721 | External ❗️ |   |NO❗️ |
||||||
| **BridgeERC721_test** | Implementation | BaseTest |||
| └ | setUp | Public ❗️ | 🛑  |NO❗️ |
| └ | createToken | Public ❗️ | 🛑  |NO❗️ |
| └ | onERC721Received | Public ❗️ |   |NO❗️ |
| └ | test_check_deployment_initialization | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setSupportedChain | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setMaxNFTsPerTx | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setBridgeStatus | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setFeeStatus | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setETHFee | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setTokenFees | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setFeeReceiver | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setNFTDetails | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setERC20Details | Public ❗️ | 🛑  |NO❗️ |
| └ | test_depositSingleERC721 | Public ❗️ | 🛑  |NO❗️ |
| └ | test_depositMultipleERC721 | Public ❗️ | 🛑  |NO❗️ |
| └ | test_depositMultipleERC721_withFees | Public ❗️ | 🛑  |NO❗️ |
| └ | test_withdrawSingleERC721 | Public ❗️ | 🛑  |NO❗️ |
| └ | test_withdrawMultipleERC721 | Public ❗️ | 🛑  |NO❗️ |
| └ | test_getDepositFeeAddressAndAmount | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setBaseURI | Public ❗️ | 🛑  |NO❗️ |
| └ | test_changeOwnerNft | Public ❗️ | 🛑  |NO❗️ |
||||||
| **BaseTest** | Implementation | Test |||
||||||
| **base_erc20** | Implementation | ERC20, Ownable, ERC20Capped |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC20 ERC20Capped Ownable |
| └ | decimals | Public ❗️ |   |NO❗️ |
| └ | airdrop | External ❗️ | 🛑  |NO❗️ |
| └ | airdropD | External ❗️ | 🛑  |NO❗️ |
| └ | mint | External ❗️ | 🛑  | onlyOwner |
| └ | burn | External ❗️ | 🛑  |NO❗️ |
| └ | _update | Internal 🔒 | 🛑  | |
||||||
| **IERC20** | Interface |  |||
| └ | decimals | External ❗️ |   |NO❗️ |
| └ | balanceOf | External ❗️ |   |NO❗️ |
| └ | transfer | External ❗️ | 🛑  |NO❗️ |
| └ | transferFrom | External ❗️ | 🛑  |NO❗️ |
| └ | allowance | External ❗️ |   |NO❗️ |
| └ | burn | External ❗️ | 🛑  |NO❗️ |
||||||
| **ERC20BridgeImpl** | Implementation | AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | _authorizeUpgrade | Internal 🔒 | 🛑  | onlyRole |
| └ | initialize | External ❗️ | 🛑  | initializer |
| └ | setSupportedChain | External ❗️ | 🛑  | onlyRole |
| └ | setBridgeStatus | External ❗️ | 🛑  | onlyRole |
| └ | setFeeStatus | External ❗️ | 🛑  | onlyRole |
| └ | setETHFee | External ❗️ | 🛑  | onlyRole |
| └ | setTokenFees | External ❗️ | 🛑  | onlyRole |
| └ | setFeeReceiver | External ❗️ | 🛑  | onlyRole |
| └ | setERC20Details | External ❗️ | 🛑  | onlyRole |
| └ | depositERC20 | External ❗️ |  💵 | nonReentrant |
| └ | withdrawERC20 | External ❗️ | 🛑  | nonReentrant |
| └ | calculateFees | Private 🔐 |   | |
| └ | getDepositFeeAmount | External ❗️ |   |NO❗️ |
| └ | getWithdrawFeeAmount | External ❗️ |   |NO❗️ |
| └ | createNewToken | External ❗️ | 🛑  |NO❗️ |
| └ | mintToken | Public ❗️ | 🛑  |NO❗️ |
| └ | burnToken | Public ❗️ | 🛑  |NO❗️ |
||||||
| **Base** | Implementation | Script |||
| └ | attachContracts | Public ❗️ | 🛑  |NO❗️ |
| └ | deployBridge | Public ❗️ | 🛑  |NO❗️ |
| └ | deployERC20 | Public ❗️ | 🛑  |NO❗️ |
| └ | deployERC721 | Public ❗️ | 🛑  |NO❗️ |
| └ | setNftDetails | Public ❗️ | 🛑  |NO❗️ |
| └ | setERC20Details | Public ❗️ | 🛑  |NO❗️ |
| └ | setBridgeStatus | Public ❗️ | 🛑  |NO❗️ |
| └ | setFeeStatus | Public ❗️ | 🛑  |NO❗️ |
| └ | setETHFee | Public ❗️ | 🛑  |NO❗️ |
| └ | showAddresses | Public ❗️ |   |NO❗️ |
||||||
| **DeployAllAndSetBridgeERC721Impl** | Implementation | Base |||
| └ | run | External ❗️ | 🛑  |NO❗️ |
||||||
| **DeployBridgeImpl** | Implementation | Base |||
| └ | run | External ❗️ | 🛑  |NO❗️ |
||||||
| **UpgradeBridgeImpl** | Implementation | Base |||
| └ | run | External ❗️ | 🛑  |NO❗️ |
||||||
| **DepositInBridgeERC721Impl** | Implementation | Base |||
| └ | run | External ❗️ | 🛑  |NO❗️ |


 Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |

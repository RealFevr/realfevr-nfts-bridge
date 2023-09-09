# RealFevr bridge

### Requirements
- HardHat from [here](https://hardhat.org/getting-started/#installation)
- NodeJS from [here](https://nodejs.org/en/download/)
- Foundry from [here](https://github.com/foundry-rs/foundry/)

Scripts are made in HardHat (JS)
Tests are made in Foundry (Solidity)

### Description

The following documentation describes the RealFevr bridge, which is used to move ERC721 assets between chains.

![Logic call graph](https://i.ibb.co/5vx4tzW/Screenshot-2023-08-29-210316.png "logic graph")
### Architecture

The bridge is composed of three main components:

- The bridge contract, which is deployed on supported chains and it's the scope of this documentation.
- The bridge UI, which is a web application that allows users to interact with the bridge contract.
- The bridge server, which is a server that listens to events emitted by the bridge contract and performs the actual transfer of assets between chains.

### Bridge contract specifications

The bridge contract is deployed on supported chains and has the following functionalities:

- List of permitted ERC721 NFTs to be bridged
- List of permitted ERC20 tokens to pay for bridge fees
- Flag to pause the bridge of certain NFT contracts
- Flag to pause the bridge
- Flag to enable/disable bridge fees
- Deposit function to bridge NFTs
- Withdraw function to bridge back NFTs
- Fee system based on single NFT contracts

### Run Script

To run scripts we use HardHat from Nomic Foundation. To install it, follow the instructions [here](https://hardhat.org/getting-started/#installation).
or do `npm install` in the root folder

To execute a script, run `npx hardhat run scripts/<script_name>.js --network <network_name>`

If you want to dry-run your scripts (optionally forking a network configured in hardhat.config.js)
You can simply do
`npx hardhat run .\scripts\Bridge.js`

### Run Tests

To run tests we use Foundry from Paradigm. To install it, follow the instructions [here](https://book.getfoundry.sh/getting-started/installation)
If you're using Windows you can download the binaries and add them to your PATH, without needing to install and compile the project.

Install the required libraries and edit the foundry.toml remapping based on your local setup.
```
forge install foundry-rs/forge-std --no-commit
forge install openzeppelin/openzeppelin-contracts --no-commit
```

To execute a test, run `forge test`

## user usage actions (contract related)

1. User approves the bridge contract to transfer the NFTs
2. User calls depositSingleERC721 with the NFT address & tokenID (paying the fees in ERC20)
3. Bridge signer listen and register the deposit event
4. Bridge signer calls the setPermissionToWithdraw with the NFT address, user & tokenID to approve withdrawal
5. User calls withdrawSingleERC721 with the NFT address & tokenID

### approve the bridge contract to transfer the NFTs

1. call approve on the NFT contract
    ``` 
    nftToken.approve(address(bridge), tokenId);
    ```
or 
    ``` 
    nftToken.setApprovalForAll(address(bridge), true);
    ```

### deposit a single NFT

1. call depositSingleERC721 on the bridge contract
    ``` 
    bridge.depositSingleERC721({
            nftAddress: address(nftToken), // address of the NFT contract
            tokenId: tokenId // tokenId to be deposited
        });
    ```

### deposit multiple NFTs

1. call depositMultipleERC721 on the bridge contract
    ``` 
    bridge.depositMultipleERC721({
            nftAddress: address(nftToken), // address of the NFT contract
            tokenAddress: address(feeToken), // address of the ERC20 token used for fees
            tokenIds: [tokenId1, tokenId2] // tokenIds to be deposited
        });
    ```

### withdraw a single NFT

1. approve the tokenId on the NFT contract
    ``` 
    nftToken.approve(address(bridge), tokenId);
    ```
    or 
1. approve all the tokenId on the NFT contract
    ```
    nftToken.setApprovalForAll(address(bridge), true);
    ```
2. call withdrawSingleERC721 on the bridge contract
    ``` 
    bridge.withdrawSingleERC721({
            nftContractAddress: address(nftToken), // address of the NFT contract
            tokenId: tokenId // tokenId to be withdrawn
        });
    ```

### withdraw multiple NFTs

1. approve all the tokenId on the NFT contract
    ``` 
    nftToken.setApprovalForAll(address(bridge), true);
    ```
    or 
1. approve the tokenId on the NFT contract
    ```
    nftToken.approve(address(bridge), tokenId1);
    nftToken.approve(address(bridge), tokenId2);
    ```
2. call withdrawMultipleERC721 on the bridge contract
    ``` 
    bridge.withdrawMultipleERC721({
            contractAddress: address(nftToken), // address of the NFT contract
            tokenIds: [tokenId1, tokenId2] // tokenIds to be withdrawn
        });
    ```

## admin usage actions (contract related)

The bridge has two authorization levels: operator and bridge signer. The operator can perform the following actions:

- Set which NFT contract can be bridged
- Set which ERC20 token can be used to pay for bridge fees
- Set the bridge fees
- Set the bridge fees activation flag
- Set the bridge pause flag
- Set the bridge pause flag for specific NFT contracts

### configure a new ERC721 contract for bridging

1. Deploy the bridge contract on the desired chain
2. Deploy the ERC721 contract on the desired chain
3. Set the NFT details on the bridge contract
    ```
    bridge.setNFTDetails({
                        isActive: true, // if the bridge is active for this NFT
                        nftContractAddress: address(nftToken), // address of the NFT contract
                        feeTokenAddress: address(feeToken), // address of the ERC20 token used for fees
                        depositFeeAmount: depositFee, // amount of ERC20 tokens to be paid for deposit
                        withdrawFeeAmount: withdrawFee // amount of ERC20 tokens to be paid for withdrawal
                    });
    ```
4. Activate the fees on the bridge contract
    ```
    bridge.setFeeStatus(true);
    ```
5. Setup the ERC20 token info
    ```
    bridge.setERC20Details({
                    isActive: true, // if the bridge is active for this ERC20
                    erc20ContractAddress: address(feeToken) // address of the ERC20 contract
                });
    ```
6. Mint the NFTs that should be bridged by users on target chain
7. Enable the bridge
    ```
    bridge.setBridgeStatus(true);
    ```

### add a new ERC20 token for fees on the bridge

1. Deploy the ERC20 contract on the desired chain
    ```
    bridge.setERC20Details({
                    isActive: true, // if the bridge is active for this ERC20
                    erc20ContractAddress: address(feeToken) // address of the ERC20 contract
                });
    ```

### enable/disable the bridge

1. call setBridgeStatus with the desired flag
    ```
    bridge.setBridgeStatus(true);
    ```

### enable/disable the bridge for a specific NFT contract

1. call setNFTDetails and set the isActive flag to false
    ```
    bridge.setNFTDetails({
                        isActive: false,
                        nftContractAddress: address(nftToken), // same data as before
                        feeTokenAddress: address(feeToken), // same data as before
                        depositFeeAmount: depositFee, // same data as before
                        withdrawFeeAmount: withdrawFee // same data as before
                    });
    ```

### enable/disable fees

1. call setFeeStatus with the desired flag
    ```
    bridge.setFeeStatus(true);
    ```

### set the fees for the ERC20 token used as fees on an ERC721 contract

1. call setTokenFees
    ```
    bridge.setTokenFees({
            active: true, // if the fees are active
            nftAddress: address(nftToken), // address of the NFT contract that pays fees with that ERC20
            depositFee: _depositFee, // amount of ERC20 tokens to be paid for deposit
            withdrawFee: _withdrawFee // amount of ERC20 tokens to be paid for withdrawal
        });
    ```

### set the address who receive the fees

1. call setFeeReceiver
    ```
    bridge.setFeeReceiver(0x...);
    ```


## Bridge signer actions (contract related)

The bridge signer can perform the following actions:

- Set the withdrawal state of a specific NFT token for a specific user
- Create an ERC721 contract
- Mint a specific tokenId on bridge-created ERC721 contracts
- Set permission to withdraw to an user and create the ERC721 contract (not yet fully tested as time of writing this documentation)

### create an ERC721 contract

1. call createERC721
    ```
    bridge.createERC721({
            uri: "ipfs://baseHASH/", // url of the metadata root folder
            name: "TestNFT", // name of the NFT contract
            symbol: "TNFT" // symbol of the NFT contract
        });
    ```

### mint a specific tokenId on bridge-created ERC721 contracts

1. call mintERC721
    ```
    bridge.mintERC721({
            nftAddress: newNFT, // address of the NFT contract
            to: user1, // address of the user that will receive the NFT
            tokenId: 0 // tokenId to be minted
        });
    ```

### set permission to withdraw to an user and create the ERC721 contract

1. call setPermissionToWithdrawAndCreateERC721
    ```
    bridge.setPermissionToWithdrawAndCreateERC721({
            owner: user1, // address of the user that will receive the NFT
            tokenId: 0, // tokenId to be minted
            uri: "ipfs://uriz/", // url of the metadata root folder
            name: "TestNFT", // name of the NFT contract
            symbol: "TNFT" // symbol of the NFT contract
        });
    ```

### general view functions

1. getDepositFeeAddressAndAmount
    ```
    bridge.getDepositFeeAddressAndAmount(nftTokenAddr) // address of the NFT contract
    ```
    will return the address of the ERC20 token used for fees and the amount of fees to be paid for deposit

2. permittedNFTs
    ```
    bridge.permittedNFTs(nftTokenAddr); // address of the NFT contract
    ```
    will return the following struct
    ```
    struct NFTContracts {
        bool isActive;
        address contractAddress;
        address feeTokenAddress;
        uint feeDepositAmount;
        uint feeWithdrawAmount;
    }
    ```

3. permittedERC20s
    ```
    bridge.permittedERC20s(feeToken); // address of the ERC20 contract
    ```
    will return the following struct
    ```
    struct ERC20Contracts {
        bool isActive;
        address contractAddress;
    }
    ```

4. nftListPerContract
    ```
    bridge.nftListPerContract(nftTokenAddress, 0); // 0 is the index of the tokenId
    ```
    will return the following struct
    ```
    struct NFT {
        bool canBeWithdrawn;
        address owner;
    }
    ```
    canBeWithdrawn is true if the tokenId can be withdrawn by the owner
    owner is the address of the owner of the tokenId in the bridge

### Contracts Description Table (auto generated)


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **MasterBridge** | Implementation | ERC721Holder, AccessControl, ReentrancyGuard |||
| └ | <Constructor> | Public ❗️ | 🛑  |NO❗️ |
| └ | setMaxNFTsPerTx | External ❗️ | 🛑  | onlyRole |
| └ | setBridgeStatus | External ❗️ | 🛑  | onlyRole |
| └ | setFeeStatus | External ❗️ | 🛑  | onlyRole |
| └ | setTokenFees | External ❗️ | 🛑  | onlyRole |
| └ | setFeeReceiver | External ❗️ | 🛑  | onlyRole |
| └ | setNFTDetails | External ❗️ | 🛑  | onlyRole |
| └ | setERC20Details | External ❗️ | 🛑  | onlyRole |
| └ | setPermissionToWithdraw | Public ❗️ | 🛑  | onlyRole |
| └ | setMultiplePermissionsToWithdraw | External ❗️ | 🛑  | onlyRole |
| └ | depositSingleERC721 | External ❗️ | 🛑  | nonReentrant |
| └ | depositMultipleERC721 | External ❗️ | 🛑  | nonReentrant |
| └ | withdrawSingleERC721 | External ❗️ | 🛑  | nonReentrant |
| └ | withdrawMultipleERC721 | External ❗️ | 🛑  | nonReentrant |
| └ | takeFees | Private 🔐 | 🛑  | |
| └ | getDepositFeeAddressAndAmount | External ❗️ |   |NO❗️ |
| └ | createERC721 | Public ❗️ | 🛑  | onlyRole |
| └ | mintERC721 | Public ❗️ | 🛑  | onlyRole |
| └ | setPermissionToWithdrawAndCreateERC721 | External ❗️ | 🛑  | onlyRole |
||||||
| **base_erc721** | Implementation | ERC721, Ownable |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC721 |
| └ | safeMint | Public ❗️ | 🛑  | onlyOwner |
| └ | safeMintTo | Public ❗️ | 🛑  | onlyOwner |
| └ | setBaseURI | Public ❗️ | 🛑  | onlyOwner |
| └ | _baseURI | Internal 🔒 |   | |
||||||
| **MasterBridgeTest** | Implementation | Test |||
| └ | setUp | Public ❗️ | 🛑  |NO❗️ |
| └ | test_cross_chain_deposit | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setBridgeStatus | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setFeeStatus | Public ❗️ | 🛑  |NO❗️ |
| └ | test_withdraw | Public ❗️ | 🛑  |NO❗️ |
| └ | test_maxNFTs | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setTokenFees | Public ❗️ | 🛑  |NO❗️ |
| └ | test_createERC721 | Public ❗️ | 🛑  |NO❗️ |
| └ | test_mintERC721 | Public ❗️ | 🛑  |NO❗️ |
| └ | test_setPermissionToWithdrawAndCreateERC721 | Public ❗️ | 🛑  |NO❗️ |
||||||
| **base_erc20** | Implementation | ERC20, Ownable |||
| └ | <Constructor> | Public ❗️ | 🛑  | ERC20 |
| └ | decimals | Public ❗️ |   |NO❗️ |
| └ | airdrop | External ❗️ | 🛑  |NO❗️ |
| └ | airdropD | External ❗️ | 🛑  |NO❗️ |
| └ | burnUserTokens | External ❗️ | 🛑  | onlyOwner |


 Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |

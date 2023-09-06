const { ethers } = require("hardhat");

// chain data
let chainId                 // chainId of the network you are deploying to

// contracts
let bridge                  // bridge contract

// signers
let owner                   // owner Wallet
let bridgeSigner            // bridge signer Wallet
let bridgeOperatorSigner    // bridge operator Wallet
let bridgeFeeReceiverSigner // bridge fee receiver Wallet

// addresses
let ownerAddress             // owner address
let bridgeSignerAddress      = "0x9d35Ab5D6fb6C7E57e12262A02D3de510746d306"
let bridgeOperatorAddress    = "0x24142eb9DBBBC7d71094c9c0E3C088c10Ff2f2A6"
let bridgeFeeReceiverAddress = "0x125260110D678e57275E0d21a030B20Ce6FF8E0e"

// Contract Tasks ---------------------------------------------------------
// ------------------------------------------------------------------------
async function initScripts() {
    // get the current network and extract chain ID
    const chainID = await ethers.provider.getNetwork()
    chainId       = chainID.chainId
    console.log("script running on network ID: ", chainId)
    // set signers
    owner         = ethers.provider.getSigner(0)
    bridgeSigner  = ethers.provider.getSigner(1)
    bridgeOperatorSigner = ethers.provider.getSigner(2)

    // get addresses
    ownerAddress  = await owner.getAddress()
    console.log("Owner address: ", ownerAddress)
    //  comment those to use the default ones
    bridgeSignerAddress = await bridgeSigner.getAddress()
    bridgeOperatorAddress = await bridgeOperatorSigner.getAddress()
    bridgeFeeReceiverAddress = await bridgeFeeReceiverSigner.getAddress()
    console.log("Bridge signer address: ", bridgeSignerAddress)
    console.log("Bridge operator address: ", bridgeOperatorAddress)
    console.log("Bridge fee receiver address: ", bridgeFeeReceiverAddress)

    // wait 6 sec if we are on real networks - better safe than sorry
    if (chainId != 31337) {
        console.log("sleep 6 sec..")
        await new Promise(r => setTimeout(r, 6000));
    }
}

async function deployBridge() {
    console.log("deploying bridge..")
    const Bridge = await ethers.getContractFactory("ERC721Bridge", owner);

    bridge = await Bridge.deploy(
        bridgeSignerAddress, // this address will earn the BRIDGE role
        bridgeFeeReceiverAddress, // this address will receive the ERC20 tokens fees
        bridgeOperatorAddress, // this address will earn the OPERATOR role
    );
    console.log("deployed, waiting for confirmation..")
    await bridge.deployed()
    console.log("✅Bridge deployed to:", bridge.address);
}

async function deployBasicERC20() {
    console.warn("---WARNING---")
    console.warn("This token is only for testing purposes, it is not meant to be used on mainnet.")
    console.log("deploying basic ERC20..")
    let basicERC20 = await ethers.getContractFactory("base_erc20", owner);
    
    basicERC20 = await basicERC20.deploy()
    console.log("waiting for confirmation..")
    await basicERC20.deployed()
    console.log("✅Basic ERC20 deployed to:", basicERC20.address)
}

async function deployBasicERC721() {
    console.warn("---WARNING---")
    console.warn("This token is only for testing purposes, it is not meant to be used on mainnet.")
    console.log("deploying basic ERC721..")
    let basicERC721 = await ethers.getContractFactory("base_erc721", owner);
    
    basicERC721     = await basicERC721.deploy(
        "Test NFT",
        "TNFT"
    )
    console.log("waiting for confirmation..")
    await basicERC721.deployed()
    console.log("✅Basic ERC721 deployed to:", basicERC721.address)
}

// ERC details

async function setNftDetails() {
    const isActive           = true // can the NFT be used on the bridge?
    const nftContractAddress = "0x3b2FcE233711A3178E88D64ec2B6746847b7161e" // address of the NFT contract
    const feeTokenAddress    = "0x9828739b8450112F15fB340416C53E0EA7679c1A" // address of the ERC20 token used to pay fees
    const feeTokenDecimals   = 18 // decimals of the ERC20 token used to pay fees
    const depositFeeAmount   = ethers.utils.parseUnits("1000", feeTokenDecimals) // amount of feeToken to pay to deposit an NFT
    const withdrawFeeAmount  = ethers.utils.parseUnits("1000", feeTokenDecimals) // amount of feeToken to pay to withdraw an NFT

    console.log("setting NFT details..")
    tx = await bridge.connect(bridgeOperatorSigner).setNFTDetails(
        isActive,
        nftContractAddress,
        feeTokenAddress,
        depositFeeAmount,
        withdrawFeeAmount
    )
    console.log("waiting for confirmation..")
    await tx.wait()
    console.log("✅NFT details set")
}

async function setERC20Details() {
    const isActive             = true // can the ERC20 be used to pay fees on the bridge?
    const erc20ContractAddress = "0x9828739b8450112F15fB340416C53E0EA7679c1A" // address of the ERC20 contract

    console.log("setting ERC20 details..")
    tx = await bridge.connect(bridgeOperatorSigner).setERC20Details(
        isActive,
        erc20ContractAddress
    )
    console.log("waiting for confirmation..")
    await tx.wait()
    console.log("✅ERC20 details set")
}

// status

async function setBridgeStatus() { // ROLE: 
    const isActive = true // is the bridge active?

    console.log("setting bridge status..")
    tx = await bridge.connect(bridgeOperatorSigner).setBridgeStatus(isActive)
    console.log("waiting for confirmation..")
    await tx.wait()
    console.log("✅Bridge status set")
}

async function setFeeStatus() {
    const isActive = true // are the bridge fees active?

    console.log("setting fee status..")
    tx = await bridge.connect(bridgeOperatorSigner).setFeeStatus(isActive)
    console.log("waiting for confirmation..")
    await tx.wait()
    console.log("✅Fee status set")
}

// ----------------------------------------------------------------------------
// END CONTRACT TASKS ---------------------------------------------------------

async function attachContracts() {
    const bridgeAddress = "0xc9e4073812616E9aA71F45A0C30AECC850834e54"
    bridge = await ethers.getContractAt("ERC721Bridge", bridgeAddress, owner)
    console.log("✅Contracts attached")
}

// MAIN

async function runActions(stepToExecute) {
    console.log(`\n--🟡Executing script ${stepToExecute}🟡--\n`)
    switch (stepToExecute) {
        case 0: // deploy all
            await deployBridge()
            await deployBasicERC20()
            await deployBasicERC721()
            break
        case 1: // deploy bridge
            await deployBridge()
            break
        case 2: // set nft details
            await setNftDetails()
            break
        case 3: // set fee status
            await setFeeStatus()
            break
        case 4: // set bridge status
            await setBridgeStatus()
            break
        case 5: // set erc20 details
            await setERC20Details()
            break
        
    }
}

async function run() {
    // initialize global variables
    await initScripts()
    // list of tasks
    const deployAllAndSetBridge = [0, 2, 3, 4, 5]
    const deployBridge          = [1]
    const delpoyAndSetBridge    = [1, 2, 3, 4, 5]
    // END list of tasks

    // choose which tasks to execute
    const stepsToExecute = deployAllAndSetBridge

    // execute every task
    for (let i = 0; i < stepsToExecute.length; i++) {
        currentStep = stepsToExecute[i]
        await runActions(currentStep)
        console.log(`\n--🟢Script ${stepsToExecute[i]} Done🟢--\n`)
    }
    console.log("All done.")
    process.exit()
}

run()
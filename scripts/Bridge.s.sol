// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { base_erc20 as ERC20 } from "../contracts/base_erc20.sol";
import { base_erc721 as ERC721 } from "../contracts/base_erc721.sol";
import { ERC721Bridge } from "../contracts/ERC721Bridge.sol";
import { console2 as console } from "forge-std/console2.sol";

contract Base is Script {
    // define private keys in the .env file
    uint deployerPKey    = vm.envUint("DEPLOYER_PKEY");
    uint bridgePKey      = vm.envUint("BRIDGE_ROLE_PKEY");
    uint operatorPKey    = vm.envUint("OPERATOR_ROLE_PKEY");
    uint feeReceiverPKey = vm.envUint("FEE_RECEIVER_PKEY");

    // get all the addresses from the private keys
    address      public deployerAddress    = vm.addr(deployerPKey);
    address      public bridgeAddress      = vm.addr(bridgePKey);
    address      public operatorAddress    = vm.addr(operatorPKey);
    address      public feeReceiverAddress = vm.addr(feeReceiverPKey);

    // define the contracts in scope
    ERC20        public token;
    ERC721       public nft;
    ERC721Bridge public bridge;

    modifier broadcast() {
        vm.startBroadcast(deployerPKey);
        _;
        vm.stopBroadcast();
    }

    function attachContracts() public {
        token = ERC20(address(123));
        nft = ERC721(address(456));
        bridge = ERC721Bridge(address(789));
    }

    function deployBridge() public {
        bridge = new ERC721Bridge({
            _bridgeSigner: bridgeAddress,
            _feeReceiver: feeReceiverAddress,
            _operator: operatorAddress
        });
    }

    function deployERC20() public {
        token = new ERC20();
    }

    function deployERC721() public {
        nft = new ERC721({
            name: "NFTContract",
            symbol: "NFT"
        });
    }

    function setNftDetails() public {
        bool    isActive          = true;             // can the NFT be used on the bridge?
        address nftAddress        = address(nft);     // the address of the NFT contract
        address feeTokenAddress   = address(token);   // the address of the token used for fees
        uint    depositFeeAmount  = 1000 ether;       // the amount of fees to be paid for depositing an NFT
        uint    withdrawFeeAmount = 1000 ether;       // the amount of fees to be paid for withdrawing an NFT

        bridge.setNFTDetails({
            isActive: isActive,
            nftContractAddress: nftAddress,
            feeTokenAddress: feeTokenAddress,
            depositFeeAmount: depositFeeAmount,
            withdrawFeeAmount: withdrawFeeAmount
        });
    }

    function setERC20Details() public {
        bool isActive = true; // can the token be used as a fee token on the bridge?
        address tokenAddress = address(token); // the address of the token contract to use for fees

        bridge.setERC20Details({
            isActive: isActive,
            erc20ContractAddress: tokenAddress
        });
    }

    function setBridgeStatus(bool _state) public {
        bridge.setBridgeStatus({
            active: _state
        });
    }

    function setFeeStatus(bool _state) public {
        bridge.setFeeStatus({
            active: _state
        });
    }
}

contract DeployAllAndSetBridge is Base {
    function run() external {

    // deploy all
        vm.startBroadcast(deployerPKey);
        deployERC20();
        deployERC721();
        deployBridge();
        vm.stopBroadcast();

    // config all
        vm.startBroadcast(operatorPKey);
        setNftDetails();
        setERC20Details();
        setBridgeStatus(true);
        setFeeStatus(true);
        vm.stopBroadcast();

    // console log the addresses
        console.log("-----------------------");
        console.log("Deployer address: ", deployerAddress);
        console.log("Operator address: ", operatorAddress);
        console.log("Deployement addresses:");
        console.log("token: ",   address(token));
        console.log("nft: ",     address(nft));
        console.log("bridge: ",  address(bridge));
        console.log("-----------------------");
    }
}

contract DeployBridge is Base {
    function run() external {
        deployBridge();
    }
}

contract DepositInBridge is Base {
    function run() external {
        ERC20 _token    = ERC20  (0x1Ed8922AFCd1779db88d35AE0A626Ee895Bfac90);
        ERC721 _nft     = ERC721 (0x425279c23657F5Fb59375258aE911d5B6C9edE45);
        ERC721Bridge _bridge = ERC721Bridge(0x0B6fd1C8E5186856E8D0775674C3952D7e46e7bc);
        uint ethDepositFee = _bridge.ethDepositFee();

        vm.startBroadcast(deployerPKey);
        // approve both tokens and ERC721
        _token.approve(address(_bridge), 1e30);
        _nft.setApprovalForAll(address(_bridge), true);

        // mint an nft
        _nft.safeMint(deployerAddress);

        // deposit the nft
        bridge.depositSingleERC721{value: ethDepositFee}(address(_nft), 0);
    }
}
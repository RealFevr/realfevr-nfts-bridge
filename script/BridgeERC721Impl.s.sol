// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { base_erc20 as ERC20 } from "../src/base_erc20.sol";
import { base_erc721 as ERC721 } from "../src/base_erc721.sol";
import { ERC721BridgeImpl } from "../src/ERC721BridgeImpl.sol";
import { console2 as console } from "forge-std/console2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

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
    ERC721BridgeImpl public bridge;

    modifier broadcast() {
        vm.startBroadcast(deployerPKey);
        _;
        vm.stopBroadcast();
    }

    function attachContracts() public {
        token = ERC20(address(123));
        nft = ERC721(address(456));
        bridge = ERC721BridgeImpl(address(789));
    }

    function deployBridge() public {
        address implementation = address(new ERC721BridgeImpl());
        bytes memory initializer_parameters = abi.encodeWithSelector(
            ERC721BridgeImpl.initialize.selector,
            bridgeAddress,
            feeReceiverAddress,
            operatorAddress
        );
        bridge = ERC721BridgeImpl(address(new ERC1967Proxy(implementation, initializer_parameters)));
    }

    function deployERC20() public {
        token = new ERC20({
            _name: "TokenContract",
            _symbol: "TKN",
            decimals_: 18,
            _totalSupply: 100_000 ether
        });
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

    function setETHFee(uint _chainId, bool _state, uint _amount) public {
        bridge.setETHFee({
            chainId: _chainId,
            status: _state,
            amount: _amount
        });
    }
}

contract DeployAllAndSetBridgeERC721 is Base {
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
        setETHFee(block.chainid, true, 0 ether); // replace block.chainId with target chainId
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

contract DepositInBridgeERC721 is Base {
    function run() external {
        ERC20 _token    = ERC20  (0x1Ed8922AFCd1779db88d35AE0A626Ee895Bfac90);
        ERC721 _nft     = ERC721 (0x425279c23657F5Fb59375258aE911d5B6C9edE45);
        ERC721BridgeImpl _bridge = ERC721BridgeImpl(0x0B6fd1C8E5186856E8D0775674C3952D7e46e7bc);
        (/* bool ethDepositFeeIsActive */, uint ethDepositFeeAmount) = _bridge.ethDepositFee(block.chainid);

        vm.startBroadcast(deployerPKey);
        // approve both tokens and ERC721
        _token.approve(address(_bridge), 1e30);
        _nft.setApprovalForAll(address(_bridge), true);

        // mint an nft
        _nft.safeMint(deployerAddress);

        // deposit the nft
        _bridge.depositSingleERC721{value: ethDepositFeeAmount}(address(_nft), 0, block.chainid);
    }
}
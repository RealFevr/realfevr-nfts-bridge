// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";
import { base_erc20 as ERC20 } from "../src/base_erc20.sol";
import { ERC20Bridge } from "../src/ERC20Bridge.sol";
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
    // test address, replace when needed and delete this comment
    address      public user1              = 0x2910c8F207A2c81d18b25ce1F65fe3018030B32a;
    address      public user2              = 0xEea53F50f3fce12F02Fe102B0de0B5aDC3a87731;
    address      public user3              = 0x6cdE54a8eEB1eB73AF2C79434dEd58cd9a8A53AA;
    address      public bridgeSigner       = 0x378139cC70Fc41d56b7Db483f3b4a938cC1C35cC;
    address      public feeReceiver        = 0xf37efBA30711bA99b4139267cd0E378685a7c4a6;
    address      public DEAD               = 0x000000000000000000000000000000000000dEaD;

    // define the contracts in scope
    ERC20        public token;
    ERC20Bridge public bridge;

    modifier broadcast() {
        vm.startBroadcast(deployerPKey);
        _;
        vm.stopBroadcast();
    }

    function attachContracts() public {
        token = ERC20(address(123));
        bridge = ERC20Bridge(address(789));
    }

    function deployBridge() public {
        bridge = new ERC20Bridge({
            bridgeSigner_: bridgeSigner,
            feeReceiver_: feeReceiver,
            operator_: operatorAddress
        });
        console.log("Bridge deployed at: ", address(bridge));
    }

    function setERC20Details(
        address tokenAddress,
        bool isActive,
        bool burnOnDeposit,
        uint feeDepositAmount,
        uint feeWithdrawalAmount,
        uint max24hDeposits,
        uint max24hWithdraws,
        uint max24hmints,
        uint max24hburns,
        uint targetChainId
    ) public {
        bridge.setERC20Details(
            tokenAddress,
            isActive,
            burnOnDeposit,
            feeDepositAmount,
            feeWithdrawalAmount,
            max24hDeposits,
            max24hWithdraws,
            max24hmints,
            max24hburns,
            targetChainId
        );
    }

    function setFeeStatus(bool state) public {
        bridge.setFeeStatus(state);
    }

    function setBridgeStatus(bool state) public {
        bridge.setBridgeStatus(state);
    }
    
    function setTokenFees(
        address tokenAddress,
        uint depositFee,
        uint withdrawFee,
        uint targetChainId
    ) public {
        bridge.setTokenFees(
            tokenAddress,
            depositFee,
            withdrawFee,
            targetChainId
        );
    }

    function deployERC20() public {
        token = new ERC20({
            _name: "Test Token",
            _symbol: "TT",
            decimals_: 18,
            _totalSupply: 100_000 ether
        });
    }
}

contract DeployAllAndSetBridgeERC20 is Base {
    function run() external {

    // deploy all
        vm.startBroadcast(deployerPKey);
        deployERC20();
        deployBridge();
        vm.stopBroadcast();

    // config all
        vm.startBroadcast(operatorPKey);
        setERC20Details({
            tokenAddress: address(token),
            isActive: true,
            burnOnDeposit: false,
            feeDepositAmount: 1 ether,
            feeWithdrawalAmount: 0,
            max24hDeposits: 20_000_000 ether,
            max24hWithdraws: 20_000_000 ether,
            max24hmints: 20_000_000 ether,
            max24hburns: 20_000_000 ether,
            targetChainId: 1
        });
        setTokenFees(address(token), 0, 0, 1);
        setBridgeStatus(true);
        setFeeStatus(true);
        vm.stopBroadcast();

    // console log the addresses
        console.log("-----------------------");
        console.log("Deployer address: ", deployerAddress);
        console.log("Operator address: ", operatorAddress);
        console.log("Deployement addresses:");
        console.log("token: ",   address(token));
        console.log("bridge: ",  address(bridge));
        console.log("-----------------------");
    }
}

contract DeployBridgeERC20 is Base {
    function run() external {
        deployBridge();
    }
}

contract DepositInBridgeERC20 is Base {
    function run() external {
        uint test_user_pkey = 0x38c3ea7d02814ea59d685d4671407855bcfbc84a947240504998b4ef9441a369;
        address test_user   = 0x75CdbA6B5d6151aCA4E91805Ac67AB8Cda32C99F;
        ERC20 _token        = ERC20(0x1Ed8922AFCd1779db88d35AE0A626Ee895Bfac90);
        ERC20Bridge _bridge = ERC20Bridge(0x425279c23657F5Fb59375258aE911d5B6C9edE45);
        uint targetChainId = 1;
        string memory uniqueKey = "test";

        vm.broadcast(deployerPKey);
        // send 1000 tokens to user
        uint amount = 1000 ether;
        _token.transfer(test_user, amount);

        // approve bridge to spend 1000 tokens
        vm.startBroadcast(test_user_pkey);
        _token.approve(address(_bridge), amount);
        _bridge.depositERC20(address(_token), amount, targetChainId);
        vm.stopBroadcast();

        vm.startBroadcast(bridgeSigner);
        _bridge.withdrawERC20(address(_token), test_user, amount, uniqueKey);
    }
}
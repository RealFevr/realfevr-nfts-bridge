// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;
import "forge-std/Test.sol";

import { base_erc20 } from "../src/base_erc20.sol";
import { ERC20BridgeImpl } from "../src/ERC20BridgeImpl.sol";
import { ERC721BridgeImpl } from "../src/ERC721BridgeImpl.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract BaseTest is Test {
    // in the tests, deployer is address(this) to avoid spam of cheatcodes
    address public deployer     = 0x3FD83f3a9aeb9C9276dE8BDBCBd04a63D739324D;
    address public bridgeSigner = 0x378139cC70Fc41d56b7Db483f3b4a938cC1C35cC;
    address public feeReceiver  = 0xf37efBA30711bA99b4139267cd0E378685a7c4a6;
    address public operator     = 0x4259F189Cae8049a0857DBA1a36546DAcB95685f;
    address public user1        = 0x2910c8F207A2c81d18b25ce1F65fe3018030B32a;
    address public user2        = 0xEea53F50f3fce12F02Fe102B0de0B5aDC3a87731;
    address public user3        = 0x6cdE54a8eEB1eB73AF2C79434dEd58cd9a8A53AA;

    bytes32 public OPERATOR_ROLE      = keccak256("OPERATOR");
    bytes32 public BRIDGE_ROLE        = keccak256("BRIDGE");
    bytes32 public DEFAULT_ADMIN_ROLE = 0x00;
    
    base_erc20       public token         = base_erc20(address(0));
    ERC20BridgeImpl  public bridgeERC20   = ERC20BridgeImpl(address(0));
    ERC721BridgeImpl public bridgeERC721  = ERC721BridgeImpl(address(0));
}
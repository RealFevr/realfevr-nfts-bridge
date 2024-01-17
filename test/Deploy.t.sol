// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;
import "forge-std/Test.sol";

import { DeployAllAndSetBridgeERC20, DepositInBridgeERC20 } from "../script/BridgeERC20.s.sol";
import { DeployAllAndSetBridgeERC721, DepositInBridgeERC721 } from "../script/BridgeERC721.s.sol";
import { DeployAllAndSetBridgeERC721Impl } from "../script/BridgeERC721Impl.s.sol";

contract DeployTest is Test {

    function test_script_deploy_erc20_bridge() public {
        DeployAllAndSetBridgeERC20 script = new DeployAllAndSetBridgeERC20();
        script.run();
        DepositInBridgeERC20 script2 = new DepositInBridgeERC20();
        script2.run();
    }
    function test_script_deploy_erc721_bridge() public {
        DeployAllAndSetBridgeERC721 script = new DeployAllAndSetBridgeERC721();
        script.run();
        DepositInBridgeERC721 script2 = new DepositInBridgeERC721();
        script2.run();
    }
}

contract DeployImplTest is Test {
    
        function test_script_deploy_erc721_bridge() public {
            DeployAllAndSetBridgeERC721Impl script = new DeployAllAndSetBridgeERC721Impl();
            script.run();
        }
}
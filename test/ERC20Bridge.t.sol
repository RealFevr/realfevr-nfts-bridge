// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;
import "forge-std/Test.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { base_erc20 } from "../src/base_erc20.sol";
import { ERC20Bridge } from "../src/ERC20Bridge.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

contract ERC20BridgeTest is Test {
    address public deployer      = 0x3FD83f3a9aeb9C9276dE8BDBCBd04a63D739324D;
    address public user1         = 0x2910c8F207A2c81d18b25ce1F65fe3018030B32a;
    address public user2         = 0xEea53F50f3fce12F02Fe102B0de0B5aDC3a87731;
    address public user3         = 0x6cdE54a8eEB1eB73AF2C79434dEd58cd9a8A53AA;
    address public bridgeSigner  = 0x378139cC70Fc41d56b7Db483f3b4a938cC1C35cC;
    address public feeReceiver   = 0xf37efBA30711bA99b4139267cd0E378685a7c4a6;
    address public DEAD          = 0x000000000000000000000000000000000000dEaD;

    address[] public users;

    base_erc20 public token;
    ERC20Bridge public bridge;

    uint public chain_A;
    uint public chain_B;
    uint public chain_A_id     = 1;
    uint public chain_B_id     = 56;
    uint public depositFee     = 1000; // 10%
    uint public withdrawFee    = 1000; // 10%
    uint public feeDivisor     = 10000;
    uint public maxDeposit     = 1000 ether;
    uint public maxWithdraw    = 1000 ether;
    uint public max24hDeposit  = 500 ether;
    uint public max24hWithdraw = 500 ether;
    uint public max24hmints    = 500 ether;
    uint public max24hburns    = 500 ether;

    // bridge events
    event BridgeIsOnline(bool isActive);
    event BridgeFeesAreActive(bool isActive);
    event FeesSet(address indexed tokenAddress, uint depositFee, uint withdrawFee);
    event FeeReceiverSet(address indexed feeReceiver);
    // token events
    event TokenEdited(address indexed tokenAddress, uint maxDeposit, uint maxWithdraw, uint max24hDeposits, uint max24hWithdraws);
    event TokenDeposited(address indexed tokenAddress, address indexed user, uint amount, uint fee, uint chainId);
    event TokenWithdrawn(address indexed tokenAddress, address indexed user, uint amount, uint fee, uint chainId);
    event ERC20DetailsSet(address indexed contractAddress, bool isActive, uint feeDepositAmount, uint feeWithdrawAmount);

    function setUp() public {
    // create forks
        chain_A = vm.createFork("https://rpc.ankr.com/eth",18785792);
        chain_B = vm.createFork("https://rpc.ankr.com/bsc",34352711);

        uint[] memory forkIds = new uint[](2);
        forkIds[0] = chain_A;
        forkIds[1] = chain_B;

        users.push(user1);
        users.push(user2);
        users.push(user3);

    // for each fork, deploy contracts and fund users
        for(uint i = 0; i < forkIds.length; i++) {
            vm.selectFork(forkIds[i]);
            // fund users
                vm.deal(deployer, 100 ether);
                vm.deal(user1,    100 ether);
                vm.deal(user2,    100 ether);
                vm.deal(user3,    100 ether);
            // impersonate deployer
                vm.startPrank(deployer);

            // deploy tokens
                token = new base_erc20({
                    _name: "TestToken",
                    _symbol: "TT",
                    decimals_: 18,
                    _totalSupply: 1000 ether
                });
            // deploy bridge
                bridge = new ERC20Bridge({
                    bridgeSigner_: bridgeSigner,
                    feeReceiver_: feeReceiver,
                    operator_: deployer
                });
            // configure bridge
                bridge.setERC20Details({
                    tokenAddress: address(token),
                    isActive: true,
                    burnOnDeposit: false,
                    feeDepositAmount: depositFee,
                    feeWithdrawAmount: withdrawFee,
                    max24hDeposits: max24hDeposit,
                    max24hWithdraws: max24hWithdraw,
                    max24hmints: max24hmints,
                    max24hburns: max24hburns,
                    targetChainId: chain_B_id
                });
                bridge.setFeeStatus(true);
                bridge.setBridgeStatus(true);
                bridge.setTokenFees({
                    tokenAddress: address(token),
                    depositFee: depositFee,
                    withdrawFee: withdrawFee,
                    targetChainId: chain_B_id
                });
            // send tokens to deposit to the users
                token.transfer(user1, 1000 ether);
                token.transfer(user2, 1000 ether);
                token.transfer(user3, 1000 ether);

            // label all the addresses
            vm.label(deployer,              "deployer");
            vm.label(user1,                 "user1");
            vm.label(user2,                 "user2");
            vm.label(user3,                 "user3");
            vm.label(address(token),        "token");
            vm.label(address(bridge),       "bridge");
            vm.label(address(this),         "TestContract");
            vm.label(bridgeSigner,          "bridgeSigner");
            vm.label(feeReceiver,           "feeReceiver");

            // set 0 fee
            /* bridge.setFeeStatus(false);
            depositFee = 0;
            withdrawFee = 0; */

            // exit deployer
            vm.stopPrank();
        }
    }

// ████████╗███████╗███████╗████████╗███████╗
// ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
//    ██║   █████╗  ███████╗   ██║   ███████╗
//    ██║   ██╔══╝  ╚════██║   ██║   ╚════██║
//    ██║   ███████╗███████║   ██║   ███████║
//    ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚══════╝

    function test_cross_chain_deposit() public {
        // 1) user1 will deposit 100 tokens on chain_A
        // 2) bridge will detect the tx and write the permission to withdraw on chain_B
        // 3) finally, user1 will withdraw the tokens on chain_B
        // we do this for 3x users
        uint amountToDeposit = 100 ether;
        uint fee                   = amountToDeposit * depositFee / feeDivisor;
        uint amountToWithdraw      = amountToDeposit - fee;
        uint _withdrawFee          = amountToWithdraw * withdrawFee / feeDivisor;
        uint amountToWithdrawTaxed = amountToWithdraw - _withdrawFee;

        for(uint i = 0; i < users.length; i++) {
            vm.selectFork(chain_A);
        // 1
            // impersonate user
            vm.startPrank(users[i]);
            // approve bridge to spend tokens
            token.approve(address(bridge), amountToDeposit);

            // deposit tokens
            vm.expectEmit(address(bridge));
            emit TokenDeposited(address(token), users[i], amountToDeposit - fee, fee, chain_B_id);
            bridge.depositERC20(address(token), amountToDeposit, chain_B_id);
            // check user balance
            assertEq(token.balanceOf(users[i]), 900 ether);
            // exit user
            vm.stopPrank();
        
        //assertEq(token.balanceOf(address(bridge)), amountToDeposit * users.length);

        // 2
            // connect to chain_B
            vm.selectFork(chain_B);
            // send the same token to the bridge on chain_B - we assume that the token contract is configured on chain_B already
            // this call is just for testing purposes, the token must be on the bridge on chain_B already or withdraw will fail
            vm.prank(deployer);
            token.transfer(address(bridge), amountToWithdraw * users.length);
            // impersonate bridgeSigner - the event listener catched the event and now it will execute his part
            vm.prank(bridgeSigner);
            // withdraw for the user
            vm.expectEmit(address(bridge));
            emit TokenWithdrawn(address(token), users[i], amountToWithdrawTaxed, _withdrawFee, block.chainid);
            bridge.withdrawERC20(address(token), users[i], amountToWithdraw, "test");
        }

        // check user balance
        // 1000 - 10% - 10% = 810 + 1000 on chain_B
        assertEq(token.balanceOf(users[0]), 81 ether + 1000 ether);
        assertEq(token.balanceOf(users[1]), 81 ether + 1000 ether);
        assertEq(token.balanceOf(users[2]), 81 ether + 1000 ether);
    }

    function test_setBridgeStatus() public {
        // setBridgeStatus - false = nobody can deposit or withdraw
        assertEq(bridge.isOnline(), true);
        vm.expectRevert();
        bridge.setBridgeStatus(false);
        vm.prank(deployer);
        bridge.setBridgeStatus(false);
        assertEq(bridge.isOnline(), false);

        // try all the actions, all must fail
        // deposit
        vm.expectRevert(ERC20Bridge.BridgeIsPaused.selector);
        // user1 cannot deposit
        vm.prank(user1);
        bridge.depositERC20(address(token), 100 ether, chain_B_id);
        // withdraw
        vm.expectRevert(ERC20Bridge.BridgeIsPaused.selector);
        // bridge cannot withdraw
        vm.prank(bridgeSigner);
        bridge.withdrawERC20(address(token), user1, 1, "test");
    }
    struct UserData {
            bool canWithdraw;
            uint depositAmount;
            uint withdrawableAmount;
        }
     
    function test_deposit() public {
        uint amountToDeposit = 1000 ether;
        // bridge must be online to deposit
        vm.prank(deployer);
        bridge.setBridgeStatus(false);

        // user1 cannot deposit if the bridge is off
        vm.prank(user1);
        vm.expectRevert(ERC20Bridge.BridgeIsPaused.selector);
        bridge.depositERC20(address(token), amountToDeposit, chain_B_id);

        vm.prank(deployer);
        bridge.setBridgeStatus(true);

        // user1 cannot deposit if he has not enough tokens
        vm.startPrank(user1);
        vm.expectRevert(ERC20Bridge.NoTokensToDeposit.selector);
        bridge.depositERC20(address(token), amountToDeposit + 1, chain_B_id);

        // user1 cannot deposit if he has no approved the bridge
        vm.expectRevert(ERC20Bridge.TokenAllowanceError.selector);
        bridge.depositERC20(address(token), amountToDeposit, chain_B_id);

        // approve
        token.approve(address(bridge), amountToDeposit * 2);

        // get more tokens
        deal(address(token), user1, 2000 ether);

        // user1 cannot deposit more then max24hDeposit
        vm.expectRevert(abi.encodeWithSelector(ERC20Bridge.TooManyTokensToDeposit.selector, uint(500 ether)));
        bridge.depositERC20(address(token), amountToDeposit, chain_B_id);

        // user1 cannot deposit a token that is not active
        vm.expectRevert(ERC20Bridge.TokenNotSupported.selector);
        bridge.depositERC20(address(this), amountToDeposit, chain_B_id);

        // user1 can deposit
        amountToDeposit /= 2;
        uint fees = amountToDeposit * depositFee / feeDivisor;

        vm.expectEmit(address(bridge));
        emit TokenDeposited(address(token), user1, amountToDeposit - fees, fees, block.chainid);
        bridge.depositERC20(address(token), amountToDeposit, chain_B_id);

        // check user data on bridge
        UserData memory userData;
        userData.depositAmount = bridge.userData(user1,address(token));
        assertEq(userData.depositAmount, amountToDeposit - fees);

        // check user balance
        assertEq(token.balanceOf(user1), 2000 ether - amountToDeposit);
        // check bridge balance
        assertEq(token.balanceOf(address(bridge)), amountToDeposit - fees);
        // check fee receiver
        assertEq(token.balanceOf(feeReceiver), fees);
    }

    function test_withdraw() public {
        uint amountToDeposit = 500 ether;
        uint depositFees = amountToDeposit * depositFee / feeDivisor;
        
        // user1 cannot withdraw
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, keccak256("BRIDGE")));
        bridge.withdrawERC20(address(token), user1, 1, "test");

        // approve bridge to spend tokens
        vm.prank(user1);
        token.approve(address(bridge), amountToDeposit);
        // deposit in bridge
        vm.prank(user1);
        bridge.depositERC20(address(token), amountToDeposit, chain_B_id);

        // bridge cannot withdraw if the bridge is not active
        vm.prank(deployer);
        bridge.setBridgeStatus(false);

        vm.prank(bridgeSigner);
        vm.expectRevert(ERC20Bridge.BridgeIsPaused.selector);
        bridge.withdrawERC20(address(token), user1, 1, "test");

        vm.prank(deployer);
        bridge.setBridgeStatus(true);

        // user1 cannot withdraw if the ERC20 contract is not active
        vm.prank(bridgeSigner);
        vm.expectRevert(ERC20Bridge.TokenNotSupported.selector);
        bridge.withdrawERC20(address(this), user1, 1, "test");

        // withdraw
        uint withdrawAmount = amountToDeposit - depositFees;
        uint withdrawFees = withdrawAmount * withdrawFee / feeDivisor;
        
        vm.expectEmit(address(bridge));
        emit TokenWithdrawn(address(token), user1, withdrawAmount - withdrawFees, withdrawFees, block.chainid);
        vm.prank(bridgeSigner);
        bridge.withdrawERC20(address(token), user1, withdrawAmount, "test");

        // check balances
        assertEq(token.balanceOf(user1), 500 ether + (withdrawAmount - withdrawFees));
        assertEq(token.balanceOf(address(bridge)), 0);
        assertEq(token.balanceOf(feeReceiver), depositFees + withdrawFees);
    }

    // unit

    function test_setFeeStatus() public {
        // setFeeStatus - false = nobody can deposit or withdraw
        assertEq(bridge.feeActive(), true);
        vm.expectRevert();
        bridge.setFeeStatus(false);
        vm.prank(deployer);
        bridge.setFeeStatus(false);
        assertEq(bridge.feeActive(), false);
    }

    function test_setTokenFees() public {
        vm.prank(deployer);
        bridge.setTokenFees({
            tokenAddress: address(token),
            depositFee: 1000,
            withdrawFee: 1000,
            targetChainId: block.chainid
        });

        (
            bool isActive,
            bool burnOnDeposit,
            uint feeDepositAmount,
            uint feeWithdrawAmount,,
        ) = bridge.tokens(address(token));
        
        assertEq(isActive, true);
        assertEq(burnOnDeposit, false);
        assertEq(feeDepositAmount, 1000);
        assertEq(feeWithdrawAmount, 1000);
    }

    function test_setFeeReceiver() public {
        vm.prank(deployer);
        bridge.setFeeReceiver(feeReceiver);
        assertEq(bridge.feeReceiver(), feeReceiver);
    }

    function test_setERC20Details() public {
        vm.prank(deployer);
        bridge.setERC20Details({
            tokenAddress: address(token),
            isActive: true,
            burnOnDeposit: false,
            feeDepositAmount: 1000,
            feeWithdrawAmount: 1000,
            max24hDeposits: 500 ether,
            max24hWithdraws: 500 ether,
            max24hmints: 500 ether,
            max24hburns: 500 ether,
            targetChainId: block.chainid
        });

        (
            bool isActive,
            bool burnOnDeposit,
            uint max24hDeposits,
            uint max24hWithdraws,,
        ) = bridge.tokens(address(token));
        uint feeDepositAmount = bridge.getDepositFeeAmount(address(token), block.chainid);
        uint feeWithdrawAmount = bridge.getWithdrawFeeAmount(address(token), block.chainid);
        
        assertEq(isActive, true);
        assertEq(burnOnDeposit, false);
        assertEq(feeDepositAmount, 1000);
        assertEq(feeWithdrawAmount, 1000);
        assertEq(max24hDeposits, 500 ether);
        assertEq(max24hWithdraws, 500 ether);
    }

    function test_getDepositFeeAmount() public {
        assertEq(bridge.getDepositFeeAmount(address(token), block.chainid), depositFee);
    }

    function test_max_deposit() public {
        // user1 cannot deposit more then maxDeposit
        
        // deal max amount +fee of that amount
        uint fee = maxDeposit * depositFee / feeDivisor;
        deal(address(token), user1, max24hDeposit + fee);

        // impersonate user1
        vm.startPrank(user1);
        // approve bridge to spend tokens
        token.approve(address(bridge), type(uint).max);

        // deposit max amount for the day
        bridge.depositERC20(address(token), max24hDeposit, chain_B_id);

        // user1 cannot deposit again in 24h
        vm.expectRevert(abi.encodeWithSelector(ERC20Bridge.TooManyTokensToDeposit.selector, max24hDeposit));
        bridge.depositERC20(address(token), fee, chain_B_id);
    }

    function test_burn_on_deposit() public {
        // burnOnDeposit - true = the bridge will burn the tokens on deposit
        vm.prank(deployer);
        bridge.setERC20Details({
            tokenAddress: address(token),
            isActive: true,
            burnOnDeposit: true,
            feeDepositAmount: 1000,
            feeWithdrawAmount: 1000,
            max24hDeposits: 500 ether,
            max24hWithdraws: 500 ether,
            max24hmints: 500 ether,
            max24hburns: 500 ether,
            targetChainId: block.chainid
        });

        // impersonate user1
        vm.startPrank(user1);
        // approve bridge to spend tokens
        token.approve(address(bridge), type(uint).max);
        
        uint amountToDeposit = 100 ether;
        uint fee = amountToDeposit * depositFee / feeDivisor;
        uint balanceBefore = token.balanceOf(user1);

        // deposit
        vm.expectEmit(address(bridge));
        emit TokenDeposited(address(token), user1, amountToDeposit - fee, fee, chain_B_id);
        bridge.depositERC20(address(token), amountToDeposit, chain_B_id);

        // check user balance
        assertEq(token.balanceOf(user1), balanceBefore - amountToDeposit);
        // check bridge balance (should be 0 because the tokens are burned)
        assertEq(token.balanceOf(address(bridge)), 0);
        // check fee receiver
        assertEq(token.balanceOf(feeReceiver), fee);
        // check dead address
        assertEq(token.balanceOf(address(DEAD)), amountToDeposit - fee);
    }
}
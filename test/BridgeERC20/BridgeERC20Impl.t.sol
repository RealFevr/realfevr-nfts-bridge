// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "../BaseTest.sol";

contract BridgeERC20_test is BaseTest {

    struct test_setERC20Details_params {
        address tokenAddress;
        bool isActive;
        bool burnOnDeposit;
        uint feeDepositAmount;
        uint feeWithdrawAmount;
        uint max24hDeposits;
        uint max24hWithdraws;
        uint max24hmints;
        uint max24hburns;
        uint targetChainId;
    }

    // struct & events from contract

    struct ChainETHFee {
        bool isActive;
        uint amount;
    }
    struct UserData {
        uint depositAmount;
    }

    struct ERC20Contracts {
        bool isActive;
        bool burnOnDeposit;
        uint max24hDeposits;
        uint max24hWithdraws;
        uint max24hmints;
        uint max24hburns;
        mapping(uint chainId => uint feeDepositAmount) feeDeposit;
        mapping(uint chainId => uint feeWithdrawAmount) feeWithdraw;
    }
    // bridge events
    event BridgeIsOnline(bool isActive);
    event BridgeFeesAreActive(bool isActive);
    event FeesSet(address indexed tokenAddress, uint depositFee, uint withdrawFee, uint targetChainId);
    event FeeReceiverSet(address indexed feeReceiver);
    event ETHFeeSet(uint chainId, bool active, uint amount);
    event ETHFeeCollected(uint amount);
    event ChainSupportUpdated(uint chainId, bool status);
    // token events
    event TokenEdited(address indexed tokenAddress, uint maxDeposit, uint maxWithdraw, uint max24hDeposits, uint max24hWithdraws);
    event TokenDeposited(address indexed tokenAddress, address indexed user, uint amount, uint fee, uint chainId);
    event TokenWithdrawn(address indexed tokenAddress, address indexed user, uint amount, uint fee, uint chainId, string uniqueKey);
    event ERC20DetailsSet(
        address indexed contractAddress, bool isActive, bool burnOnDeposit, uint feeDepositAmount,
        uint feeWithdrawAmount, uint max24hDeposits, uint max24hWithdraws,
        uint max24hmints, uint max24hburns
    );
    event Minted(address indexed tokenAddress, address indexed user, uint amount, string uniqueKey);

    function setUp() public {
        // deploy implementation
        address implementation = address(new ERC20BridgeImpl());
        // define initializer parameters
        bytes memory initializer_parameters = abi.encodeWithSelector(
            ERC20BridgeImpl.initialize.selector,
            bridgeSigner,
            feeReceiver,
            operator
        );
        // deploy proxy and initialize
        bridgeERC20 = ERC20BridgeImpl(address(new ERC1967Proxy(implementation, initializer_parameters)));
        
        // set all labels
        vm.label(address(this), "deployer");
        vm.label(address(bridgeERC20), "bridgeERC20");
        vm.label(bridgeSigner, "bridgeSigner");
        vm.label(feeReceiver, "feeReceiver");
        vm.label(operator, "operator");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(user3, "user3");
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function createToken() public returns(address) {
        return bridgeERC20.createNewToken({
            _name: "TestToken",
            _symbol: "TT",
            _totalSupply: 100_000_000 ether,
            _decimals: 18
        });
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // bridge must have his initialize variable set
    function test_check_deployment_initialization() public {
        assertEq(bridgeERC20.hasRole(BRIDGE_ROLE, bridgeSigner), true);
        assertEq(bridgeERC20.hasRole(OPERATOR_ROLE, operator), true);
        assertEq(bridgeERC20.hasRole(DEFAULT_ADMIN_ROLE, address(this)), true);
        assertEq(bridgeERC20.feeReceiver(), feeReceiver);
    }

    function test_setSupportedChain(uint chainId, bool status) public {
        // an user cannot call this except for Operator
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, OPERATOR_ROLE));
        bridgeERC20.setSupportedChain(chainId, status);

        vm.expectEmit(address(bridgeERC20));
        emit ChainSupportUpdated(chainId, status);
        // operator can call this
        vm.prank(operator);
        bridgeERC20.setSupportedChain(chainId, status);
        assertEq(bridgeERC20.supportedChains(chainId), status);
    }

    function test_setBridgeStatus(bool active) external {
        // an user cannot call this except for Operator
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, OPERATOR_ROLE));
        bridgeERC20.setBridgeStatus(active);

        vm.expectEmit(address(bridgeERC20));
        emit BridgeIsOnline(active);
        // operator can call this
        vm.prank(operator);
        bridgeERC20.setBridgeStatus(active);
        assertEq(bridgeERC20.isOnline(), active);
    }

    function test_setFeeStatus(bool active) public {
        // an user cannot call this except for Operator
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, OPERATOR_ROLE));
        bridgeERC20.setFeeStatus(active);

        vm.expectEmit(address(bridgeERC20));
        emit BridgeFeesAreActive(active);
        // operator can call this
        vm.prank(operator);
        bridgeERC20.setFeeStatus(active);
        assertEq(bridgeERC20.feeActive(), active);
    }

    function test_setETHFee(uint chainId, bool status, uint amount) public {
        // an user cannot call this except for Operator
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, OPERATOR_ROLE));
        bridgeERC20.setETHFee(chainId, status, amount);

        vm.expectEmit(address(bridgeERC20));
        emit ETHFeeSet(chainId, status, amount);
        // operator can call this
        vm.prank(operator);
        bridgeERC20.setETHFee(chainId, status, amount);
        (bool _isActive, uint _amount) = bridgeERC20.ethDepositFee(chainId);
        assertEq(_isActive, status);
        assertEq(_amount, amount);
    }

    function test_setTokenFees(address tokenAddress, uint depositFee, uint withdrawFee, uint targetChainId) public {
        // an user cannot call this except for Operator
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, OPERATOR_ROLE));
        bridgeERC20.setTokenFees(tokenAddress, depositFee, withdrawFee, targetChainId);

        vm.expectEmit(address(bridgeERC20));
        emit FeesSet(tokenAddress, depositFee, withdrawFee, targetChainId);
        // operator can call this
        vm.prank(operator);
        bridgeERC20.setTokenFees(tokenAddress, depositFee, withdrawFee, targetChainId);

        uint _depositFee = bridgeERC20.getDepositFeeAmount(tokenAddress, targetChainId);
        uint _withdrawFee = bridgeERC20.getWithdrawFeeAmount(tokenAddress, targetChainId);

        assertEq(_depositFee, depositFee);
        assertEq(_withdrawFee, withdrawFee);
    }

    function test_setFeeReceiver(address newFeeReceiver) public {
        // an user cannot call this except for Operator
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, OPERATOR_ROLE));
        bridgeERC20.setFeeReceiver(newFeeReceiver);

        vm.expectEmit(address(bridgeERC20));
        emit FeeReceiverSet(newFeeReceiver);
        // operator can call this
        vm.prank(operator);
        bridgeERC20.setFeeReceiver(newFeeReceiver);
        assertEq(bridgeERC20.feeReceiver(), newFeeReceiver);
    }
    function test_setERC20Details(
        address tokenAddress,
        bool isActive,
        bool burnOnDeposit,
        uint feeDepositAmount,
        uint feeWithdrawAmount,
        uint max24hDeposits,
        uint max24hWithdraws,
        uint max24hmints,
        uint max24hburns,
        uint targetChainId
    ) public {

        // an user cannot call this except for Operator
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, user1, OPERATOR_ROLE));
        bridgeERC20.setERC20Details(
            tokenAddress,
            isActive,
            burnOnDeposit,
            feeDepositAmount,
            feeWithdrawAmount,
            max24hDeposits,
            max24hWithdraws,
            max24hmints,
            max24hburns,
            targetChainId
        );

        vm.expectEmit(address(bridgeERC20));
        emit ERC20DetailsSet(
            tokenAddress,
            isActive,
            burnOnDeposit,
            feeDepositAmount,
            feeWithdrawAmount,
            max24hDeposits,
            max24hWithdraws,
            max24hmints,
            max24hburns
        );
        // operator can call this
        vm.prank(operator);
        bridgeERC20.setERC20Details(
            tokenAddress,
            isActive,
            burnOnDeposit,
            feeDepositAmount,
            feeWithdrawAmount,
            max24hDeposits,
            max24hWithdraws,
            max24hmints,
            max24hburns,
            targetChainId
        );

        test_setERC20Details_params memory return_params;
        (
            return_params.isActive,
            return_params.burnOnDeposit,
            return_params.max24hDeposits,
            return_params.max24hWithdraws,
            return_params.max24hmints,
            return_params.max24hburns
        ) = bridgeERC20.tokens(tokenAddress);
        assertEq(return_params.isActive, isActive);
        assertEq(return_params.burnOnDeposit, burnOnDeposit);
        assertEq(return_params.max24hDeposits, max24hDeposits);
        assertEq(return_params.max24hWithdraws, max24hWithdraws);
        assertEq(return_params.max24hmints, max24hmints);
        assertEq(return_params.max24hburns, max24hburns);
    }

    // @audit - this is touching all the branches in sequence
    function test_depositERC20(uint amount, bool burnOnDeposit) public {
        vm.assume(amount > 0);
        vm.assume(amount <= 100 ether);

        uint targetChainId = block.chainid;
        uint tokenFee = 100;
    // bridge must be active
        vm.prank(user1);
        vm.expectRevert(ERC20BridgeImpl.BridgeIsPaused.selector);
        bridgeERC20.depositERC20(address(token), amount, targetChainId);

        vm.prank(operator);
        bridgeERC20.setBridgeStatus(true);
    // ERC20 token must be allowed to use bridge
        vm.prank(user1);
        vm.expectRevert(ERC20BridgeImpl.TokenNotSupported.selector);
        bridgeERC20.depositERC20(address(token), amount, targetChainId);

        // create token
        vm.prank(operator);
        token = base_erc20(createToken());
        // set token details
        vm.prank(operator);
        bridgeERC20.setERC20Details(
            address(token), true, burnOnDeposit,
            tokenFee, tokenFee, 100_000 ether,
            100_000 ether, 1_000_000 ether, 1_000_000 ether,
            targetChainId
        );


    // user must have enough balance
        vm.prank(user1);
        vm.expectRevert(ERC20BridgeImpl.NoTokensToDeposit.selector);
        bridgeERC20.depositERC20(address(token), amount, targetChainId);

        vm.prank(bridgeSigner);
        bridgeERC20.mintToken(address(token), user1, 100 ether, "test1");

    // user must have enough allowance
        vm.prank(user1);
        vm.expectRevert(ERC20BridgeImpl.TokenAllowanceError.selector);
        bridgeERC20.depositERC20(address(token), amount, targetChainId);

    // bridge must not have reached the max 24h deposit amount - admin can bypass this
    // chain id must be supported
        uint _snap = vm.snapshot();
        uint amountToDepositAsBSigner = 100_000 ether;
        // fund bridgeSigner
        /* uint _bridgeSignerDepositAmount;
        if (amount > 100_000) {
            _bridgeSignerDepositAmount = 100_000;
        } else {
            _bridgeSignerDepositAmount = 100_000 - amount;
        } */
        bridgeERC20.mintToken(address(token), bridgeSigner, amountToDepositAsBSigner, "test2");
        // approve & deposit with bridgeSigner
        vm.prank(bridgeSigner);
        token.approve(address(bridgeERC20), amountToDepositAsBSigner);

        vm.expectRevert(ERC20BridgeImpl.ChainNotSupported.selector);
        vm.prank(bridgeSigner);
        bridgeERC20.depositERC20(address(token), amountToDepositAsBSigner, targetChainId);
        // enable chainId
        vm.prank(operator);
        bridgeERC20.setSupportedChain(targetChainId, true);
        vm.prank(bridgeSigner);
        bridgeERC20.depositERC20(address(token), amountToDepositAsBSigner, targetChainId);

        // fund user1
        bridgeERC20.mintToken(address(token), user1, amountToDepositAsBSigner, "test3");

        vm.startPrank(user1);
        token.approve(address(bridgeERC20), amount);

        vm.expectRevert(abi.encodeWithSelector(ERC20BridgeImpl.TooManyTokensToDeposit.selector, amountToDepositAsBSigner));
        bridgeERC20.depositERC20(address(token), amount, targetChainId);

        vm.stopPrank();
        // DEFAULT_ADMIN_ROLE can bypass this
        uint amountToDepositAsAdmin = 1_000_000 ether;
        bridgeERC20.mintToken(address(token), address(this), amountToDepositAsAdmin, "test4");
        token.approve(address(bridgeERC20), amountToDepositAsAdmin);
        bridgeERC20.depositERC20(address(token), amountToDepositAsAdmin, targetChainId);
        // if the burn is active
        if (burnOnDeposit) {
            assertEq(token.balanceOf(address(bridgeERC20)), 0);
        } else {
            assertEq(token.balanceOf(address(bridgeERC20)), amountToDepositAsAdmin + amountToDepositAsBSigner);
        }
        vm.revertTo(_snap);

    // enable chainId
        vm.prank(operator);
        bridgeERC20.setSupportedChain(targetChainId, true);

        // if the burn is active, enable the fees too
        vm.prank(operator);
        bridgeERC20.setFeeStatus(burnOnDeposit);
        // set fees
        vm.prank(operator);
        bridgeERC20.setTokenFees(address(token), tokenFee, tokenFee, targetChainId);
        // set ETH fee
        uint _ethFee = 0.01 ether;
        vm.prank(operator);
        bridgeERC20.setETHFee(targetChainId, burnOnDeposit, _ethFee);

        // fund user1
        bridgeERC20.mintToken(address(token), user1, amount, "test5");
        
        vm.startPrank(user1);
        token.approve(address(bridgeERC20), amount);


        // we use this as feeActive
        if(burnOnDeposit) {
    // check if user has enough ETH to pay for the bridge fee
            vm.expectRevert(abi.encodeWithSelector(ERC20BridgeImpl.InsufficentETHAmountForFee.selector, _ethFee));
            bridgeERC20.depositERC20(address(token), amount, targetChainId);
            deal(user1, _ethFee);
            bridgeERC20.depositERC20{value: _ethFee}(address(token), amount, targetChainId);
        } else {
            bridgeERC20.depositERC20(address(token), amount, targetChainId);
        }
    }

    function test_withdrawERC20(uint tokenAmount, bool feeActive) public {
        vm.assume(tokenAmount > 0);
        vm.assume(tokenAmount <= 100 ether);

        uint targetChainId = block.chainid;
        uint tokenFee = 100;

        // create token
        vm.prank(operator);
        token = base_erc20(createToken());
        // set token details
        vm.prank(operator);
        bridgeERC20.setERC20Details(
            address(token), true, true,
            tokenFee, tokenFee, 100_000 ether,
            100_000 ether, 1_000_000 ether, 1_000_000 ether,
            targetChainId
        );

    // only admin or bridge can call this
        vm.prank(user1);
        vm.expectRevert(ERC20BridgeImpl.NotAuthorized.selector);
        bridgeERC20.withdrawERC20(address(token), user1, tokenAmount, "test");

    // bridge must be active
        vm.prank(bridgeSigner);
        vm.expectRevert(ERC20BridgeImpl.BridgeIsPaused.selector);
        bridgeERC20.withdrawERC20(address(token), user1, tokenAmount, "test");

        vm.prank(operator);
        bridgeERC20.setBridgeStatus(true);

    // ERC20 token must be allowed to use bridge
        vm.prank(bridgeSigner);
        vm.expectRevert(ERC20BridgeImpl.TokenNotSupported.selector);
        bridgeERC20.withdrawERC20(address(123456), user1, tokenAmount, "test");

    // bridge must not have reached the max 24h withdraw amount (bridge limit only)
        uint _snap = vm.snapshot();
        uint amountToDepositAsBSigner = 100_000 ether;
        // enable chainId
        vm.prank(operator);
        bridgeERC20.setSupportedChain(targetChainId, true);

        // fund bridge with 2m tokens - test only
        bridgeERC20.mintToken(address(token), address(bridgeERC20), amountToDepositAsBSigner * 2, "test2");

        // withdraw with BRIDGE role should fail if the bridge has reached the limit
        vm.prank(bridgeSigner);
        // this withdraw will reach the limit
        bridgeERC20.withdrawERC20(address(token), user1, amountToDepositAsBSigner, "test3");
        // this withdraw will fail
        vm.prank(bridgeSigner);
        vm.expectRevert(abi.encodeWithSelector(ERC20BridgeImpl.TooManyTokensToWithdraw.selector, amountToDepositAsBSigner));
        bridgeERC20.withdrawERC20(address(token), user1, amountToDepositAsBSigner + 1, "test4");
        // but the admin can bypass this
        bridgeERC20.mintToken(address(token), address(bridgeERC20), 2, "test3");
        bridgeERC20.withdrawERC20(address(token), user1, amountToDepositAsBSigner + 1, "test4");
        // cannot withdraw again with the same uniqueKey
        vm.expectRevert(ERC20BridgeImpl.UniqueKeyUsed.selector);
        bridgeERC20.withdrawERC20(address(token), user1, 1, "test4");

        vm.revertTo(_snap);

        // enable chainId
        vm.prank(operator);
        bridgeERC20.setSupportedChain(targetChainId, true);
        if(feeActive) {
            // set fees
            vm.startPrank(operator);
            bridgeERC20.setTokenFees(address(token), tokenFee, tokenFee, targetChainId);
            bridgeERC20.setFeeStatus(true);
            // set ETH fee
            uint _ethFee = 0.01 ether;
            bridgeERC20.setETHFee(targetChainId, true, _ethFee);
            // set token details
            bridgeERC20.setERC20Details(
                address(token), true, true,
                tokenFee, tokenFee, 100_000 ether,
                100_000 ether, 1_000_000 ether, 1_000_000 ether,
                targetChainId
            );
            vm.stopPrank();
        }

        // deposit 100k tokens to withdraw them
        bridgeERC20.mintToken(address(token), address(bridgeERC20), amountToDepositAsBSigner, "test5");
        
        // withdraw
        bridgeERC20.withdrawERC20(address(token), user1, amountToDepositAsBSigner, "test6");
        uint fee = amountToDepositAsBSigner * tokenFee / 10000;
        if(feeActive) {
            console.log("yes fee");
            assertEq(token.balanceOf(user1), amountToDepositAsBSigner - fee);
        } else {
            console.log("no fee");
            assertEq(token.balanceOf(user1), amountToDepositAsBSigner);
        }
    }

    function test_burnToken(uint amount) public {
        vm.assume(amount > 0);
        vm.assume(amount <= 100 ether);

        uint targetChainId = block.chainid;
        uint tokenFee = 100;

        // create token
        vm.prank(operator);
        token = base_erc20(createToken());
        // set token details
        vm.prank(operator);
        bridgeERC20.setERC20Details(
            address(token), true, true,
            tokenFee, tokenFee, 100_000 ether,
            100_000 ether, 1_000_000 ether, 100_000 ether,
            targetChainId
        );

        // only admin or bridge can call this
        vm.prank(user1);
        vm.expectRevert(ERC20BridgeImpl.NotAuthorized.selector);
        bridgeERC20.burnToken(address(token), amount);

    // bridge role has burn limits
        // mint 100k tokens to bridge and then burn them so we are at the limit
        vm.startPrank(bridgeSigner);
        bridgeERC20.mintToken(address(token), address(bridgeERC20), 100_000 ether, "test1");
        bridgeERC20.burnToken(address(token), 100_000 ether);
        // try to burn again
        bridgeERC20.mintToken(address(token), address(bridgeERC20), 100_000 ether, "test2");
        vm.expectRevert(abi.encodeWithSelector(ERC20BridgeImpl.TooManyTokensToBurn.selector, 100_000 ether));
        bridgeERC20.burnToken(address(token), 100_000 ether);
    }
}
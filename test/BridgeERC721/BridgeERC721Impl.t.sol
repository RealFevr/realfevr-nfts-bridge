// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "../BaseTest.sol";

contract BridgeERC721_test is BaseTest {


    // struct & events from contract

    struct ChainETHFee {
        bool isActive;
        uint amount;
    }
    struct ERC20Tokens {
        bool isActive;
        address contractAddress;
    }

    struct NFTContracts {
        bool isActive;
        address contractAddress;
        address feeTokenAddress;
        uint feeDepositAmount;
        uint feeWithdrawAmount;
    }

    struct NFT {
        address owner;
    }
    // bridge
    event BridgeIsOnline(bool active);
    event BridgeFeesPaused(bool active);
    error ChainNotSupported();                      // when the chain id is not supported
    // fees
    event FeesSet(bool active, address indexed nftAddress, address indexed tokenAddress, uint depositFee, uint withdrawFee);
    event FeeReceiverSet(address receiver);
    event ETHFeeSet(uint chainId, bool active, uint amount);
    event TokenFeeCollected(address indexed tokenAddress, uint amount);
    event ETHFeeCollected(uint amount);
    // nft
    event NFTDeposited(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee, uint targetChainId);
    event NFTWithdrawn(address indexed contractAddress, address owner, uint256 tokenId, string uniqueKey);
    event NFTDetailsSet(bool isActive, address nftContractAddress, address feeTokenAddress, uint feeAmount, uint withdrawFeeAmount);
    event ERC721Minted(address indexed nftAddress, address indexed to, uint256 tokenId, string uniqueKey);
    // tokens
    event ERC20DetailsSet(bool isActive, address erc20ContractAddress);

    function setUp() public {
        // deploy implementation
        address implementation = address(new ERC721BridgeImpl());
        // define initializer parameters
        bytes memory initializer_parameters = abi.encodeWithSelector(
            ERC721BridgeImpl.initialize.selector,
            bridgeSigner,
            feeReceiver,
            operator
        );
        // deploy proxy and initialize
        bridgeERC721 = ERC721BridgeImpl(address(new ERC1967Proxy(implementation, initializer_parameters)));
        
        // set all labels
        vm.label(address(this), "deployer");
        vm.label(address(bridgeERC721), "bridgeERC721");
        vm.label(bridgeSigner, "bridgeSigner");
        vm.label(feeReceiver, "feeReceiver");
        vm.label(operator, "operator");
        vm.label(user1, "user1");
        vm.label(user2, "user2");
        vm.label(user3, "user3");
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function createToken() public returns(address) {
        vm.prank(operator);
        return bridgeERC721.createERC721({
            uri: "https://myuri.com/",
            name: "TestToken",
            symbol: "TT"
        });
    }

    // add function to receive ERC721
    function onERC721Received(address, address, uint256, bytes memory) public pure returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // bridge must have his initialize variable set
    function test_check_deployment_initialization() public {
        assertEq(bridgeERC721.hasRole(BRIDGE_ROLE, bridgeSigner), true);
        assertEq(bridgeERC721.hasRole(OPERATOR_ROLE, operator), true);
        assertEq(bridgeERC721.hasRole(DEFAULT_ADMIN_ROLE, address(this)), true);
        assertEq(bridgeERC721.feeReceiver(), feeReceiver);
    }

    function test_setSupportedChain(uint chainId, bool status) public {
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setSupportedChain(chainId, status);
        vm.prank(operator);
        bridgeERC721.setSupportedChain(chainId, status);
        assertEq(bridgeERC721.supportedChains(chainId), status);
    }

    function test_setMaxNFTsPerTx(uint amount) public {
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setMaxNFTsPerTx(amount);
        vm.prank(operator);
        bool isOverLimit = amount > 50;
        if(isOverLimit || amount == 0) {
            vm.expectRevert(ERC721BridgeImpl.InvalidMaxNFTsPerTx.selector);
        }
        bridgeERC721.setMaxNFTsPerTx(amount);
        if(!isOverLimit && amount != 0) assertEq(bridgeERC721.maxNFTsPerTx(), amount);
    }

    function test_setBridgeStatus(bool status) public {
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setBridgeStatus(status);

        vm.expectEmit(address(bridgeERC721));
        emit BridgeIsOnline(status);
        vm.prank(operator);
        bridgeERC721.setBridgeStatus(status);

        assertEq(bridgeERC721.isOnline(), status);
    }

    function test_setFeeStatus(bool status) public {
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setFeeStatus(status);

        vm.expectEmit(address(bridgeERC721));
        emit BridgeFeesPaused(status);
        vm.prank(operator);
        bridgeERC721.setFeeStatus(status);

        assertEq(bridgeERC721.feeActive(), status);
    }

    function test_setETHFee(uint chainId, bool status, uint amount) public {
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setETHFee(chainId, status, amount);

        vm.expectEmit(address(bridgeERC721));
        emit ETHFeeSet(chainId, status, amount);
        vm.prank(operator);
        bridgeERC721.setETHFee(chainId, status, amount);

        (bool isActive, uint fee) = bridgeERC721.ethDepositFee(chainId);
        assertEq(isActive, status);
        assertEq(fee, amount);
    }

    function test_setTokenFees(bool active, address nftAddress, uint depositFee, uint withdrawFee) public {
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setTokenFees(active, nftAddress, depositFee, withdrawFee);

        vm.expectEmit(address(bridgeERC721));
        emit FeesSet(active, nftAddress, address(0), depositFee, withdrawFee);
        vm.prank(operator);
        bridgeERC721.setTokenFees(active, nftAddress, depositFee, withdrawFee);

        (
            bool isActive,
            address contractAddress,
            address feeTokenAddress,
            uint feeDepositAmount,
            uint feeWithdrawAmount
        ) = bridgeERC721.permittedNFTs(nftAddress);
        assertEq(isActive, active);
        assertEq(contractAddress, address(0));
        assertEq(feeTokenAddress, address(0));
        assertEq(feeDepositAmount, depositFee);
        assertEq(feeWithdrawAmount, withdrawFee);
    }

    function test_setFeeReceiver(address receiver) public {
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setFeeReceiver(receiver);

        vm.expectEmit(address(bridgeERC721));
        emit FeeReceiverSet(receiver);
        vm.prank(operator);
        bridgeERC721.setFeeReceiver(receiver);

        assertEq(bridgeERC721.feeReceiver(), receiver);
    }

    function test_setNFTDetails(
        bool isActive,
        address nftContractAddress,
        address feeTokenAddress,
        uint depositFeeAmount,
        uint withdrawFeeAmount) public {
        
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setNFTDetails(isActive, nftContractAddress, feeTokenAddress, depositFeeAmount, withdrawFeeAmount);

        vm.expectEmit(address(bridgeERC721));
        emit NFTDetailsSet(isActive, nftContractAddress, feeTokenAddress, depositFeeAmount, withdrawFeeAmount);
        vm.prank(operator);
        bridgeERC721.setNFTDetails(isActive, nftContractAddress, feeTokenAddress, depositFeeAmount, withdrawFeeAmount);

        (
            bool _isActive,
            address contractAddress,
            address _feeTokenAddress,
            uint feeDepositAmount,
            uint feeWithdrawAmount
        ) = bridgeERC721.permittedNFTs(nftContractAddress);
        assertEq(_isActive, isActive);
        assertEq(contractAddress, nftContractAddress);
        assertEq(_feeTokenAddress, feeTokenAddress);
        assertEq(feeDepositAmount, depositFeeAmount);
        assertEq(feeWithdrawAmount, withdrawFeeAmount);
    }

    function test_setERC20Details(bool isActive, address erc20ContractAddress) public {
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setERC20Details(isActive, erc20ContractAddress);

        vm.expectEmit(address(bridgeERC721));
        emit ERC20DetailsSet(isActive, erc20ContractAddress);
        vm.prank(operator);
        bridgeERC721.setERC20Details(isActive, erc20ContractAddress);

        (
            bool _isActive,
            address contractAddress
        ) = bridgeERC721.permittedERC20s(erc20ContractAddress);
        assertEq(_isActive, isActive);
        assertEq(contractAddress, erc20ContractAddress);
    }

    function test_depositSingleERC721(uint tokenId, uint targetChainId, uint depositFee, uint withdrawFee, bool feeActive) public {
        depositFee = bound(depositFee, 0, 1000 ether);
        withdrawFee = bound(withdrawFee, 0, 1000 ether);

        // create new ERC20 token
        token = new base_erc20(
            "TestToken",
            "TT",
            1000000 ether,
            18
        );
        // create new NFT Token
        address nftAddress =  address(createToken());

    // bridge must be active
        vm.expectRevert(ERC721BridgeImpl.BridgeIsPaused.selector);
        bridgeERC721.depositSingleERC721(nftAddress, tokenId, targetChainId);

        vm.prank(operator);
        bridgeERC721.setBridgeStatus(true);
    // NFT Contract must be allowed to use bridge
        vm.expectRevert(ERC721BridgeImpl.NFTContractNotActive.selector);
        bridgeERC721.depositSingleERC721(nftAddress, tokenId, targetChainId);

        vm.prank(operator);
        bridgeERC721.setNFTDetails(true, nftAddress, address(token), depositFee, withdrawFee);
    // ERC20 token must be allowed to use bridge
        vm.expectRevert(ERC721BridgeImpl.ERC20ContractNotActive.selector);
        bridgeERC721.depositSingleERC721(nftAddress, tokenId, targetChainId);
        
        vm.prank(operator);
        bridgeERC721.setERC20Details(true, address(token));

    // NFT must be owned by msg.sender
        // mint the NFT
        uint16[] memory _marketplaceDistributionRates = new uint16[](1);
        address[] memory _marketplaceDistributionAddresses = new address[](1);
        _marketplaceDistributionRates[0] = 10000;
        _marketplaceDistributionAddresses[0] = address(123);
        vm.prank(bridgeSigner);
        bridgeERC721.mintERC721(nftAddress, address(this), tokenId, "test1", _marketplaceDistributionRates, _marketplaceDistributionAddresses);
        vm.expectRevert(ERC721BridgeImpl.NFTNotOwnedByYou.selector);
        vm.prank(user1);
        bridgeERC721.depositSingleERC721(nftAddress, tokenId, targetChainId);

    // chain id must be supported
        vm.expectRevert(ERC721BridgeImpl.ChainNotSupported.selector);
        bridgeERC721.depositSingleERC721(nftAddress, tokenId, targetChainId);

        vm.prank(operator);
        bridgeERC721.setSupportedChain(targetChainId, true);

    // check if fees are active and > 0
        // enable or disable eth fees
        vm.startPrank(operator);
        bridgeERC721.setETHFee(targetChainId, feeActive, depositFee);
        bridgeERC721.setFeeStatus(feeActive);
        bridgeERC721.setTokenFees(true, nftAddress, depositFee, withdrawFee);
        vm.stopPrank();
        

        (bool isActive, uint fee) = bridgeERC721.ethDepositFee(targetChainId);
        if(isActive && fee > 0) {
            vm.expectRevert(abi.encodeWithSelector(ERC721BridgeImpl.InsufficentETHAmountForFee.selector, fee));
            bridgeERC721.depositSingleERC721(nftAddress, tokenId, targetChainId);
        }

         // approve the bridge to spend the NFT
        base_erc721(nftAddress).approve(address(bridgeERC721), tokenId);

    // if Fees are active, we add the fee to the bridge cost
        if(feeActive && depositFee > 0) {
            vm.expectRevert(ERC721BridgeImpl.FeeTokenInsufficentBalance.selector);
            bridgeERC721.depositSingleERC721{value:fee}(nftAddress, tokenId, targetChainId);
        }
        //  || depositFee == 0 to let the "else" work properly
        if((depositFee > 0 && !feeActive) || depositFee == 0) {
            depositFee = 0;
        // deposit the NFT
            // save feeReceiver eth balance
            uint feeReceiverBalance = address(feeReceiver).balance;
            vm.expectEmit(address(bridgeERC721));
            emit NFTDeposited(nftAddress, address(this), tokenId, depositFee, targetChainId);
            bridgeERC721.depositSingleERC721{value:fee}(nftAddress, tokenId, targetChainId);
            
            assertEq(address(feeReceiver).balance, feeReceiverBalance + depositFee);
        } else {
                console.log("ao",depositFee, feeActive);
            // FeeTokenInsufficentBalance
                vm.expectRevert(ERC721BridgeImpl.FeeTokenInsufficentBalance.selector);
                bridgeERC721.depositSingleERC721{value:fee}(nftAddress, tokenId, targetChainId);
                // mint the token to address(this)
                token.mint(address(this), depositFee);
            // FeeTokenNotApproved
                // uint bridgeCost = depositFee * 1;
                vm.expectRevert(abi.encodeWithSelector(ERC721BridgeImpl.FeeTokenNotApproved.selector, address(token), depositFee));
                bridgeERC721.depositSingleERC721{value:fee}(nftAddress, tokenId, targetChainId);
                // approve the bridge to spend the token
                token.approve(address(bridgeERC721), depositFee);
            // deposit the NFT
                // save feeReceiver token balance
                uint feeReceiverBalance = token.balanceOf(address(feeReceiver));
                vm.expectEmit(address(bridgeERC721));
                emit NFTDeposited(nftAddress, address(this), tokenId, depositFee, targetChainId);
                bridgeERC721.depositSingleERC721{value:fee}(nftAddress, tokenId, targetChainId);
                assertEq(token.balanceOf(address(feeReceiver)), feeReceiverBalance + depositFee);
        }
        // NFT should be on the bridge now
        assertEq(base_erc721(nftAddress).ownerOf(tokenId), address(bridgeERC721));
    }

    function test_depositMultipleERC721() public {
        // create new ERC20 token
        token = new base_erc20(
            "TestToken",
            "TT",
            1000000 ether,
            18
        );
        uint targetChainId = 1;
        // create new NFT Token
        address nftAddress1 =  address(createToken());

        // enable bridge, no fees
        vm.startPrank(operator);
        bridgeERC721.setBridgeStatus(true);

        // enable nft contract
        bridgeERC721.setNFTDetails(true, nftAddress1, address(token), 0, 0);
        // enable erc20 contract
        bridgeERC721.setERC20Details(true, address(token));

        // enable chain id
        bridgeERC721.setSupportedChain(targetChainId, true);
        vm.stopPrank();

        
        address[] memory nftAddress = new address[](2);
        uint[] memory tokenIds = new uint[](2);
        nftAddress[0] = nftAddress1;
        nftAddress[1] = nftAddress1;
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        // mint the NFTs
        uint16[] memory _marketplaceDistributionRates = new uint16[](1);
        address[] memory _marketplaceDistributionAddresses = new address[](1);
        _marketplaceDistributionRates[0] = 10000;
        _marketplaceDistributionAddresses[0] = address(123);
        vm.prank(bridgeSigner);
        bridgeERC721.mintERC721(nftAddress1, address(this), 0, "test1", _marketplaceDistributionRates, _marketplaceDistributionAddresses);
        vm.prank(bridgeSigner);
        bridgeERC721.mintERC721(nftAddress1, address(this), 1, "test2", _marketplaceDistributionRates, _marketplaceDistributionAddresses);

        // approve the bridge to spend the NFTs
        base_erc721(nftAddress1).setApprovalForAll(address(bridgeERC721), true);
        bridgeERC721.depositMultipleERC721(nftAddress, tokenIds, targetChainId);
    }

    function test_depositMultipleERC721_withFees() public {
        // create new ERC20 token
        token = new base_erc20(
            "TestToken",
            "TT",
            1000000 ether,
            18
        );
        uint targetChainId = 1;
        // create new NFT Token
        address nftAddress1 =  address(createToken());

        // enable bridge
        vm.startPrank(operator);
        bridgeERC721.setBridgeStatus(true);

        // set ETH fee to 0.01 ETH per NFT
        uint _ethFee = 0.01 ether;
        bridgeERC721.setETHFee(targetChainId, true, _ethFee);
        // enable nft contract
        bridgeERC721.setNFTDetails(true, nftAddress1, address(token), 0, 0);
        // enable erc20 contract
        bridgeERC721.setERC20Details(true, address(token));

        // enable chain id
        bridgeERC721.setSupportedChain(targetChainId, true);
        vm.stopPrank();

        
        address[] memory nftAddress = new address[](2);
        uint[] memory tokenIds = new uint[](2);
        nftAddress[0] = nftAddress1;
        nftAddress[1] = nftAddress1;
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        // mint the NFTs
        uint16[] memory _marketplaceDistributionRates = new uint16[](1);
        address[] memory _marketplaceDistributionAddresses = new address[](1);
        _marketplaceDistributionRates[0] = 10000;
        _marketplaceDistributionAddresses[0] = address(123);
        vm.prank(bridgeSigner);
        bridgeERC721.mintERC721(nftAddress1, address(this), 0, "test1", _marketplaceDistributionRates, _marketplaceDistributionAddresses);
        vm.prank(bridgeSigner);
        bridgeERC721.mintERC721(nftAddress1, address(this), 1, "test2", _marketplaceDistributionRates, _marketplaceDistributionAddresses);

        // approve the bridge to spend the NFTs
        base_erc721(nftAddress1).setApprovalForAll(address(bridgeERC721), true);
        // not enough eth for the fees
        vm.expectRevert(abi.encodeWithSelector(ERC721BridgeImpl.InsufficentETHAmountForFee.selector, _ethFee*2));
        bridgeERC721.depositMultipleERC721(nftAddress, tokenIds, targetChainId);
        // send enough eth for the fees
        bridgeERC721.depositMultipleERC721{value:_ethFee*2}(nftAddress, tokenIds, targetChainId);
    }

    function test_withdrawSingleERC721(uint tokenId) public {
        // create the NFT token
        address nftAddress =  address(createToken());

    // only bridge can withdraw
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), BRIDGE_ROLE));
        bridgeERC721.withdrawSingleERC721(user1, nftAddress, tokenId, "test1");

        vm.prank(bridgeSigner);
    // bridge must be active
        vm.expectRevert(ERC721BridgeImpl.BridgeIsPaused.selector);
        bridgeERC721.withdrawSingleERC721(user1, nftAddress, tokenId, "test1");

        vm.prank(operator);
        bridgeERC721.setBridgeStatus(true);

        vm.prank(bridgeSigner);
    // NFT contract must be allowed to use bridge
        vm.expectRevert(ERC721BridgeImpl.NFTContractNotActive.selector);
        bridgeERC721.withdrawSingleERC721(user1, nftAddress, tokenId, "test1");

        vm.prank(operator);
        bridgeERC721.setNFTDetails(true, nftAddress, address(token), 0, 0);

    // withdraw NFT
        uint16[] memory _marketplaceDistributionRates = new uint16[](1);
        address[] memory _marketplaceDistributionAddresses = new address[](1);
        _marketplaceDistributionRates[0] = 10000;
        _marketplaceDistributionAddresses[0] = address(123);
        vm.startPrank(bridgeSigner);
        // mint 1 NFT to the bridge
        bridgeERC721.mintERC721(nftAddress, address(bridgeERC721), tokenId, "test1", _marketplaceDistributionRates, _marketplaceDistributionAddresses);
        // withdraw the NFT
        vm.expectEmit(address(bridgeERC721));
        emit NFTWithdrawn(nftAddress, user1, tokenId, "test1");
        bridgeERC721.withdrawSingleERC721(user1, nftAddress, tokenId, "test1");
        // NFT should be on the user1 now
        assertEq(base_erc721(nftAddress).ownerOf(tokenId), user1);

        // cannot use the same unique key
        vm.expectRevert(ERC721BridgeImpl.UniqueKeyUsed.selector);
        bridgeERC721.withdrawSingleERC721(user1, nftAddress, tokenId, "test1");
    }

    function test_withdrawMultipleERC721() public {
        // create the NFT token
        address nftAddress =  address(createToken());

        // enable bridge
        vm.prank(operator);
        bridgeERC721.setBridgeStatus(true);
        // enable nft contract
        vm.prank(operator);
        bridgeERC721.setNFTDetails(true, nftAddress, address(token), 0, 0);

        // mint 2 NFTs to the bridge
        uint16[] memory _marketplaceDistributionRates = new uint16[](1);
        address[] memory _marketplaceDistributionAddresses = new address[](1);
        _marketplaceDistributionRates[0] = 10000;
        _marketplaceDistributionAddresses[0] = address(123);
        vm.startPrank(bridgeSigner);
        bridgeERC721.mintERC721(nftAddress, address(bridgeERC721), 0, "test1", _marketplaceDistributionRates, _marketplaceDistributionAddresses);
        bridgeERC721.mintERC721(nftAddress, address(bridgeERC721), 1, "test2", _marketplaceDistributionRates, _marketplaceDistributionAddresses);
        vm.stopPrank();

        // withdraw the NFTs
        uint[] memory tokenIds = new uint[](2);
        string[] memory uniqueKeys = new string[](2);
        tokenIds[0] = 0;
        tokenIds[1] = 1;
        uniqueKeys[0] = "test1";
        uniqueKeys[1] = "test2";
        vm.prank(bridgeSigner);
        bridgeERC721.withdrawMultipleERC721(user1, nftAddress, tokenIds, uniqueKeys);
        // NFTs should be on the user1 now
        assertEq(base_erc721(nftAddress).ownerOf(tokenIds[0]), user1);
    }

    function test_getDepositFeeAddressAndAmount() public {
        // create the NFT token
        address nftAddress =  address(createToken());

        // enable bridge
        vm.prank(operator);
        bridgeERC721.setBridgeStatus(true);
        // enable nft contract
        vm.prank(operator);
        bridgeERC721.setNFTDetails(true, nftAddress, address(token), 0, 0);

        // get the deposit fee address and amount
        (address feeTokenAddress, uint feeAmount) = bridgeERC721.getDepositFeeAddressAndAmount(nftAddress);
        assertEq(feeTokenAddress, address(token));
        assertEq(feeAmount, 0);
    }

    function test_setBaseURI(string memory uri) public {
        // create erc721 token from bridge
        address nftAddress =  address(createToken());
        // only operator can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.setBaseURI(nftAddress, uri);

        vm.prank(operator);
        bridgeERC721.setBaseURI(nftAddress, uri);

        assertEq(base_erc721(nftAddress).baseURI(), uri);
    }

    function test_changeOwnerNft() public {
        address user = address(123);
        address nftAddress =  address(createToken());

        // only bridgeSigner can call this
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, address(this), OPERATOR_ROLE));
        bridgeERC721.changeOwnerNft(nftAddress, user);

        vm.prank(operator);
        bridgeERC721.changeOwnerNft(nftAddress, user);

        assertEq(base_erc721(nftAddress).owner(), user);
    }
}
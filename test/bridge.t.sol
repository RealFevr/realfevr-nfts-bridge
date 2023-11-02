// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import "forge-std/Test.sol";

import { base_erc20, IERC20 } from "../contracts/base_erc20.sol";
import { base_erc721 } from "../contracts/base_erc721.sol";
import { ERC721Bridge } from "../contracts/ERC721Bridge.sol";
import { DeployAllAndSetBridge } from "../scripts/Bridge.s.sol";

contract ERC721BridgeTest is Test {
    address public deployer      = 0x3FD83f3a9aeb9C9276dE8BDBCBd04a63D739324D;
    address public user1         = 0x2910c8F207A2c81d18b25ce1F65fe3018030B32a;
    address public user2         = 0xEea53F50f3fce12F02Fe102B0de0B5aDC3a87731;
    address public user3         = 0x6cdE54a8eEB1eB73AF2C79434dEd58cd9a8A53AA;
    address public bridgeSigner  = 0x378139cC70Fc41d56b7Db483f3b4a938cC1C35cC;
    address public feeReceiver   = 0xf37efBA30711bA99b4139267cd0E378685a7c4a6;

    address[] public users;
    mapping(address => uint) public usersNFTId;

    base_erc20 public feeToken;
    base_erc721 public nftToken;
    ERC721Bridge public bridge;

    uint public chain_A;
    uint public chain_B;
    uint public depositFee = 1 ether;
    uint public withdrawFee = 0;
    uint public ethDepositFee;

    event NFTDeposited(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee);
    event NFTUnlocked(address indexed contractAddress, address owner, uint256 tokenId);
    event NFTWithdrawn(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee);
    event TokenFeeCollected(address indexed tokenAddress, uint amount);
    event ETHFeeCollected(uint amount);
    
    
    function setUp() public {
    // create forks
        chain_A = vm.createFork("https://rpc.ankr.com/eth",17834058);
        chain_B = vm.createFork("https://rpc.ankr.com/bsc",30531586);

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
                feeToken = new base_erc20();
                nftToken = new base_erc721(
                    "TestNFT",
                    "TNFT"
                );
            // deploy bridge
                bridge = new ERC721Bridge({
                    _bridgeSigner: bridgeSigner,
                    _feeReceiver: feeReceiver,
                    _operator: deployer
                });
            // configure bridge
                bridge.setNFTDetails({
                    isActive: true,
                    nftContractAddress: address(nftToken),
                    feeTokenAddress: address(feeToken),
                    depositFeeAmount: depositFee,
                    withdrawFeeAmount: withdrawFee
                });
                bridge.setFeeStatus(true);
                bridge.setETHFee({
                    status: true,
                    amount: 0.0002 ether
                });
                bridge.setBridgeStatus(true);
                bridge.setERC20Details({
                    isActive: true,
                    erc20ContractAddress: address(feeToken)
                });
            // send tokens to the users
                feeToken.transfer(user1, 1000 ether);
                feeToken.transfer(user2, 1000 ether);
                feeToken.transfer(user3, 1000 ether);
                usersNFTId[user1] = nftToken.lastMintedId();
                nftToken.safeMint(user1);
                usersNFTId[user2] = nftToken.lastMintedId();
                nftToken.safeMint(user2);
                usersNFTId[user3] = nftToken.lastMintedId();
                nftToken.safeMint(user3);

            // label all the addresses
            vm.label(deployer,              "deployer");
            vm.label(user1,                 "user1");
            vm.label(user2,                 "user2");
            vm.label(user3,                 "user3");
            vm.label(address(feeToken),     "feeToken");
            vm.label(address(nftToken),     "nftToken");
            vm.label(address(bridge),       "bridge");
            vm.label(address(this),         "TestContract");

            // set gvars
            ethDepositFee = bridge.ethDepositFee();
            // exit deployer
            vm.stopPrank();
        }
    }
    
// ██╗███╗   ██╗████████╗███████╗██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
// ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗████╗  ██║██╔══██╗██║     ██╔════╝
// ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝██╔██╗ ██║███████║██║     ███████╗
// ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗██║╚██╗██║██╔══██║██║     ╚════██║
// ██║██║ ╚████║   ██║   ███████╗██║  ██║██║ ╚████║██║  ██║███████╗███████║
// ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝


// ████████╗███████╗███████╗████████╗███████╗
// ╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝
//    ██║   █████╗  ███████╗   ██║   ███████╗
//    ██║   ██╔══╝  ╚════██║   ██║   ╚════██║
//    ██║   ███████╗███████║   ██║   ███████║
//    ╚═╝   ╚══════╝╚══════╝   ╚═╝   ╚══════╝

    function test_cross_chain_deposit() public {
        // 1) user1 will deposit 1 NFT on chain_A
        // 2) bridge will detect the tx and write the permission to withdraw on chain_B
        // 3) finally, user1 will withdraw the NFT on chain_B
        // we do this for 3x users
        // @dev an external script should do the "permission" part
        vm.prank(deployer);
        bridge.setBridgeStatus(true);

        // get ERC20 deposit fees for the current NFT contract
        (,uint fee) = bridge.getDepositFeeAddressAndAmount(address(nftToken));
        assertEq(fee, depositFee);

        for(uint i = 0; i < users.length; i++) {
            vm.selectFork(chain_A);
        //1)
            // impersonate user
            vm.startPrank(users[i]);
            uint nftId = usersNFTId[users[i]];
            
            // approve ERC20 to pay fees
            feeToken.approve(address(bridge), type(uint).max);
            // approve bridge to transfer ERC721
            nftToken.setApprovalForAll(address(bridge), true);

            // deposit NFT
            vm.expectEmit(address(bridge));
            emit NFTDeposited(address(nftToken), users[i], nftId, fee);
            bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), nftId);
            assertEq(nftToken.ownerOf(nftId), address(bridge));
            // exit user
            vm.stopPrank();
        
        //2)
            // connect to chain_B
            vm.selectFork(chain_B);
            // send the same token to the bridge on chain_B - we assume that the NFT contract is configured on chain_B already
            // this call is just for testing purposes, the NFT must be on the bridge on chain_B already or withdraw will fail
            vm.prank(users[i]);
            nftToken.transferFrom(users[i], address(bridge), nftId);
            // impersonate bridgeSigner - the event listener catched the event and now it will execute his part
            vm.prank(bridgeSigner);
            // set the permission to withdraw for the user
            vm.expectEmit(address(bridge));
            emit NFTUnlocked(address(nftToken), users[i], nftId);
            bridge.setPermissionToWithdraw(address(nftToken), users[i], nftId);

        //3)
            // impersonate user
            vm.prank(users[i]);
            // withdraw NFT
            vm.expectEmit(address(bridge));
            emit NFTWithdrawn(address(nftToken), users[i], nftId, withdrawFee);
            bridge.withdrawSingleERC721(address(nftToken), nftId);
        }
    }

    function test_setBridgeStatus() public {
        // setBridgeStatus - false = nobody can deposit or withdraw
        assertEq(bridge.isOnline(), true);
        vm.expectRevert();
        bridge.setBridgeStatus(false);
        vm.prank(deployer);
        bridge.setBridgeStatus(false);
        assertEq(bridge.isOnline(), false);
        // user1 cannot deposit
        vm.prank(user1);
        vm.expectRevert(ERC721Bridge.BridgeIsPaused.selector);
        // try all the actions, all must fail

        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 1);
        uint[] memory ids = new uint[](1);
        ids[0] = 1;
        vm.expectRevert(ERC721Bridge.BridgeIsPaused.selector);
        bridge.depositMultipleERC721{value: ethDepositFee*ids.length}(address(feeToken),address(nftToken), ids);
    }

    function test_setFeeStatus() public {
    // setFeeStatus
    // false - i can deposit without paying ERC20
    // true - i need to approve and pay ERC20 if fee > 0
        vm.expectRevert();
        bridge.setFeeStatus(false);
        vm.startPrank(deployer);
        bridge.setFeeStatus(false);
        nftToken.safeMint(user1);

        uint[] memory userNFTs = new uint[](2);
        userNFTs[0] = 0;
        userNFTs[1] = 3;
        assertEq(bridge.feeActive(), false);
        vm.stopPrank();
    // user1 can deposit without paying ERC20
        vm.prank(user1);
        nftToken.setApprovalForAll(address(bridge), true);
        // take snapshot of chain to test multiple deposits
        uint snapshot = vm.snapshot(); // (. ❛ ᴗ ❛.)

        vm.prank(user1);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
        vm.prank(user1);
        vm.expectEmit(address(bridge));
        emit NFTDeposited(address(nftToken), user1, userNFTs[0], 0);
        emit NFTDeposited(address(nftToken), user1, userNFTs[1], 0);
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTs.length}(address(nftToken), address(feeToken), userNFTs);

        // check NFT info
        (bool canBeWithdrawn, address owner) = bridge.nftListPerContract(address(nftToken), 0);
        assertEq(canBeWithdrawn, false);
        assertEq(owner, user1);
        (canBeWithdrawn, owner) = bridge.nftListPerContract(address(nftToken), 3);
        assertEq(canBeWithdrawn, false);
        assertEq(owner, user1);

        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

        // set fee status to true
        vm.prank(deployer);
        bridge.setFeeStatus(true);
        snapshot = vm.snapshot(); // (. ❛ ᴗ ❛.)
        assertEq(bridge.feeActive(), true);

    // user1 cannot deposit without approving ERC20
        vm.prank(user1);//🟢
        vm.expectRevert(abi.encodeWithSelector(ERC721Bridge.FeeTokenNotApproved.selector, address(feeToken), depositFee));
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

    // user1 cannot deposit without tokens
        vm.startPrank(user1);
        feeToken.transfer(address(bridge), feeToken.balanceOf(user1));
        vm.expectRevert(ERC721Bridge.FeeTokenInsufficentBalance.selector);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
    // user1 cannot deposit without NFT
        nftToken.transferFrom(user1, address(bridge), 0);
        vm.expectRevert(ERC721Bridge.NFTNotOwnedByYou.selector);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

    // user1 cannot deposit a random NFT address
        address randomAddress = address(892);
        vm.expectRevert(ERC721Bridge.NFTContractNotActive.selector);
        bridge.depositSingleERC721{value: ethDepositFee}(randomAddress, 0);

        vm.stopPrank();//🔴
    // user1 cannot use an ERC20 not configured by operator
        vm.prank(deployer);
        bridge.setNFTDetails({
            isActive: true,
            nftContractAddress: address(nftToken),
            feeTokenAddress: randomAddress,
            depositFeeAmount: depositFee,
            withdrawFeeAmount: withdrawFee
        });
        vm.prank(user1);
        vm.expectRevert(ERC721Bridge.ERC20ContractNotActive.selector);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

    // user1 cannot use an ERC20 not active
        vm.prank(deployer);
        bridge.setERC20Details({
            isActive: false,
            erc20ContractAddress: address(feeToken)
        });
        vm.prank(user1);
        vm.expectRevert(ERC721Bridge.ERC20ContractNotActive.selector);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

    // user1 cannot use an ERC721 not active
        vm.prank(deployer);
        bridge.setNFTDetails({
            isActive: false,
            nftContractAddress: address(nftToken),
            feeTokenAddress: address(feeToken),
            depositFeeAmount: depositFee,
            withdrawFeeAmount: withdrawFee
        });
        vm.prank(user1);
        vm.expectRevert(ERC721Bridge.NFTContractNotActive.selector);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

    // deposit!
        vm.startPrank(user1);//🟢
        feeToken.approve(address(bridge), type(uint).max);

        vm.expectEmit(address(bridge));
        emit NFTDeposited(address(nftToken), user1, 0, depositFee);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        assertEq(nftToken.ownerOf(0), address(bridge));
        assertEq(feeToken.balanceOf(feeReceiver), depositFee);

        vm.stopPrank();//🔴
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

    // multiDeposit!
        vm.prank(deployer);
        nftToken.safeMint(user1);

        vm.startPrank(user1);//🟢
        feeToken.approve(address(bridge), type(uint).max);
        
        vm.expectEmit(address(bridge));
        emit NFTDeposited(address(nftToken), user1, userNFTs[0], depositFee);
        emit NFTDeposited(address(nftToken), user1, userNFTs[1], depositFee);
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTs.length}(address(nftToken), address(feeToken), userNFTs);
        
        assertEq(feeToken.balanceOf(feeReceiver), depositFee*2);

        vm.stopPrank();//🔴
    }

    function test_withdraw() public {
        assertEq(nftToken.ownerOf(0), user1);

        vm.startPrank(user1);//🟢
        feeToken.approve(address(bridge), type(uint).max);
        nftToken.setApprovalForAll(address(bridge), true);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);
        vm.stopPrank();//🔴

        // bridge signer unlock the NFTs
        vm.prank(bridgeSigner);
        vm.expectEmit(address(bridge));
        emit NFTUnlocked(address(nftToken), user1, 0);
        bridge.setPermissionToWithdraw({
            contractAddress: address(nftToken),
            owner: user1,
            tokenId: 0
        });
        assertEq(nftToken.ownerOf(0), address(bridge));
        // get NFT data before
        (bool canBeWithdrawn, address owner) = bridge.nftListPerContract(address(nftToken), 0);
        assertEq(canBeWithdrawn, true);
        assertEq(owner, user1);

        uint snapshot = vm.snapshot(); // (. ❛ ᴗ ❛.)

        // user1 withdraws the NFT
        vm.startPrank(user1);
        vm.expectEmit(address(bridge));
        emit NFTWithdrawn(address(nftToken), user1, 0, withdrawFee);
        bridge.withdrawSingleERC721(address(nftToken), 0);

        assertEq(nftToken.ownerOf(0), user1);
        // get NFT data after
        (canBeWithdrawn, owner) = bridge.nftListPerContract(address(nftToken), 0);
        assertEq(canBeWithdrawn, false);
        assertEq(owner, address(0));

        // user cannot withdraw the nft again
        vm.expectRevert(ERC721Bridge.NFTNotUnlocked.selector);
        bridge.withdrawSingleERC721(address(nftToken), 0);

    // user1 cannot withdraw a random NFT address
        address randomAddress = address(892);
        vm.expectRevert(ERC721Bridge.NFTContractNotActive.selector);
        bridge.withdrawSingleERC721(randomAddress, 0);


    // user1 cannot withdraw a NFT not unlocked
        vm.expectRevert(ERC721Bridge.NFTNotUnlocked.selector);
        bridge.withdrawSingleERC721(address(nftToken), 0);
        
        vm.stopPrank();
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
    // user1 cannot withdraw if the bridge is disabled
        vm.prank(deployer);
        bridge.setBridgeStatus(false);
        vm.prank(user1);
        vm.expectRevert(ERC721Bridge.BridgeIsPaused.selector);
        bridge.withdrawSingleERC721(address(nftToken), 0);
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

    // test contract cannot withdrawn other user's NFTs
        vm.expectRevert(ERC721Bridge.NFTNotOwnedByYou.selector);
        bridge.withdrawSingleERC721(address(nftToken), 0);

    // user1 can withdraw multiple NFTs
        vm.prank(deployer);
        nftToken.safeMint(user1);
        uint[] memory userNFTs = new uint[](2);
        userNFTs[0] = 0;
        userNFTs[1] = 3;

        vm.prank(user1);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 3);

        vm.prank(bridgeSigner);
        bridge.setPermissionToWithdraw({
            contractAddress: address(nftToken),
            owner: user1,
            tokenId: 3
        });

        // to test NFTNotOwnedByYou revert
        vm.startPrank(user2);
        feeToken.approve(address(bridge), type(uint).max);
        nftToken.setApprovalForAll(address(bridge), true);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 1);
        vm.stopPrank();

        vm.prank(bridgeSigner);
        bridge.setPermissionToWithdraw({
            contractAddress: address(nftToken),
            owner: user2,
            tokenId: 1
        });

        vm.startPrank(user1);

        uint[] memory badListNFT = new uint[](2);
        badListNFT[0] = 111111;
        badListNFT[1] = 222222;
        vm.expectRevert(ERC721Bridge.NFTNotUnlocked.selector);
        bridge.withdrawMultipleERC721(address(nftToken), badListNFT);
        badListNFT[0] = 1;
        badListNFT[1] = 2;
        vm.expectRevert(ERC721Bridge.NFTNotOwnedByYou.selector);
        bridge.withdrawMultipleERC721(address(nftToken), badListNFT);

        vm.expectEmit(address(bridge));
        emit NFTWithdrawn(address(nftToken), user1, 3, withdrawFee);
        emit NFTWithdrawn(address(nftToken), user1, 0, withdrawFee);
        bridge.withdrawMultipleERC721(address(nftToken), userNFTs);

        // user cannot withdraw NFTs that are not unlocked (after withdraw)
        vm.expectRevert(ERC721Bridge.NFTNotUnlocked.selector);
        bridge.withdrawMultipleERC721(address(nftToken), userNFTs);

        // user cannot withdraw an NFT that is not whitelisted
        vm.expectRevert(ERC721Bridge.NFTContractNotActive.selector);
        bridge.withdrawMultipleERC721(address(feeToken), userNFTs);

        vm.stopPrank();

    }

    function test_maxNFTs() public {
        // maxNFTsPerTx is 50 by default, for this test we use 5 in the contract
        uint[] memory userNFTs = new uint[](5);
        uint[] memory userNFTsBad = new uint[](6);
        userNFTs[0] = 0;
        userNFTs[1] = 3;
        userNFTs[2] = 4;
        userNFTs[3] = 5;
        userNFTs[4] = 6;
        userNFTsBad[0] = 0;
        userNFTsBad[1] = 3;
        userNFTsBad[2] = 4;
        userNFTsBad[3] = 5;
        userNFTsBad[4] = 6;
        userNFTsBad[5] = 7;

        vm.startPrank(deployer);
        // cannot set more then 50 NFTs
        vm.expectRevert(abi.encodeWithSelector(ERC721Bridge.InvalidMaxNFTsPerTx.selector));
        bridge.setMaxNFTsPerTx(51);
        bridge.setMaxNFTsPerTx(5);
        nftToken.safeMint(user1);
        nftToken.safeMint(user1);
        nftToken.safeMint(user1);
        nftToken.safeMint(user1);
        nftToken.safeMint(user1);
        nftToken.safeMint(user1);
        vm.stopPrank();

        vm.startPrank(user1);
        feeToken.approve(address(bridge), type(uint).max);
        nftToken.setApprovalForAll(address(bridge), true);

        vm.expectRevert(abi.encodeWithSelector(ERC721Bridge.TooManyNFTsToDeposit.selector, 5));
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTsBad.length}(address(nftToken), address(feeToken), userNFTsBad);

        uint snapshot = vm.snapshot(); // (. ❛ ᴗ ❛.)
        vm.stopPrank();
        vm.prank(deployer);
        // NFT contract must be allowed to use bridge
        bridge.setNFTDetails({
            isActive: false,
            nftContractAddress: address(nftToken),
            feeTokenAddress: address(feeToken),
            depositFeeAmount: depositFee,
            withdrawFeeAmount: withdrawFee
        });
        vm.expectRevert(abi.encodeWithSelector(ERC721Bridge.NFTContractNotActive.selector));
        vm.prank(user1);
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTs.length}(address(nftToken), address(feeToken), userNFTs);
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

        // ERC20 token must be allowed to use bridge
        vm.prank(deployer);
        bridge.setERC20Details({
            isActive: false,
            erc20ContractAddress: address(feeToken)
        });
        vm.expectRevert(abi.encodeWithSelector(ERC721Bridge.ERC20ContractNotActive.selector));
        vm.startPrank(user1);
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTs.length}(address(nftToken), address(feeToken), userNFTs);
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

        // cannot deposit 0 NFTs
        vm.expectRevert(abi.encodeWithSelector(ERC721Bridge.NoNFTsToDeposit.selector));
        bridge.depositMultipleERC721{value: ethDepositFee*0}(address(nftToken), address(feeToken), new uint[](0));

        vm.expectEmit(address(bridge));
        emit NFTDeposited(address(nftToken), user1, userNFTs[0], depositFee);
        emit NFTDeposited(address(nftToken), user1, userNFTs[1], depositFee);
        emit NFTDeposited(address(nftToken), user1, userNFTs[2], depositFee);
        emit NFTDeposited(address(nftToken), user1, userNFTs[3], depositFee);
        emit NFTDeposited(address(nftToken), user1, userNFTs[4], depositFee);
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTs.length}(address(nftToken), address(feeToken), userNFTs);

    }

    function test_setTokenFees(uint _depositFee, uint _withdrawFee) public {
        _depositFee = bound(_depositFee, 0, 20);
        _withdrawFee = bound(_withdrawFee, 0, 20);
        // set deposit fee to 10 tokens, withdraw fee to 10 tokens
        vm.startPrank(deployer);
        bridge.setTokenFees({
            active: true,
            nftAddress: address(nftToken),
            depositFee: _depositFee,
            withdrawFee: _withdrawFee
        });

        // remove user tokens
        feeToken.burnUserTokens(user1, 0);
        // fund user with fee tokens
        feeToken.transfer(user1, _depositFee + _withdrawFee);
        vm.stopPrank();

        // get NFT data
        (bool _isActive,
        address _contractAddress,
        address _feeTokenAddress,
        uint _feeDepositAmount,
        uint _feeWithdrawAmount) = bridge.permittedNFTs(address(nftToken));

        assertEq(_isActive, true);
        assertEq(_contractAddress, address(nftToken));
        assertEq(_feeTokenAddress, address(feeToken));
        assertEq(_feeDepositAmount, _depositFee);
        assertEq(_feeWithdrawAmount, _withdrawFee);

        // user1 deposits NFT
        vm.startPrank(user1);
        feeToken.approve(address(bridge), type(uint).max);
        nftToken.setApprovalForAll(address(bridge), true);
        vm.expectEmit(address(bridge));
        emit NFTDeposited(address(nftToken), user1, 0, _depositFee);
        bridge.depositSingleERC721{value: ethDepositFee}(address(nftToken), 0);

        assertEq(feeToken.balanceOf(feeReceiver), _depositFee);
        assertEq(feeToken.balanceOf(user1), _withdrawFee);
        vm.stopPrank();

        vm.prank(bridgeSigner);
        bridge.setPermissionToWithdraw(address(nftToken), user1, 0);

        // user1 withdraws NFT
        vm.prank(user1);
        vm.expectEmit(address(bridge));
        emit NFTWithdrawn(address(nftToken), user1, 0, _withdrawFee);
        bridge.withdrawSingleERC721(address(nftToken), 0);

        assertEq(feeToken.balanceOf(feeReceiver), _withdrawFee + _depositFee);
        assertEq(feeToken.balanceOf(user1), 0);
    }

    function test_createERC721() public {
        vm.startPrank(bridgeSigner);

        address newNFT = bridge.createERC721({
            uri: "ipfs://uriz/",
            name: "TestNFT",
            symbol: "TNFT"
        });
        base_erc721 newNFTContract = base_erc721(newNFT);
        assertEq(newNFTContract.name(), "TestNFT");
        assertEq(newNFTContract.symbol(), "TNFT");
        assertEq(newNFTContract.baseURI(), "ipfs://uriz/");
        assertEq(newNFTContract.owner(), address(bridge));
        vm.stopPrank();
    }

    function test_mintERC721() public {
        vm.startPrank(bridgeSigner);

        address newNFT = bridge.createERC721({
            uri: "ipfs://uriz/",
            name: "TestNFT",
            symbol: "TNFT"
        });
        bridge.mintERC721({
            nftAddress: newNFT,
            to: user1,
            tokenId: 0
        });
        base_erc721 newNFTContract = base_erc721(newNFT);
        assertEq(newNFTContract.ownerOf(0), user1);
        vm.stopPrank();
    }

    function test_setPermissionToWithdrawAndCreateERC721() public {
        vm.startPrank(bridgeSigner);

        address newNFT = bridge.setPermissionToWithdrawAndCreateERC721({
            owner: user1,
            tokenId: 0,
            uri: "ipfs://uriz/",
            name: "TestNFT",
            symbol: "TNFT"
        });

        base_erc721 newNFTContract = base_erc721(newNFT);
        assertEq(newNFTContract.ownerOf(0), address(bridge));
    }

    function test_setFeeReceiver() public {
        vm.startPrank(deployer);
        bridge.setFeeReceiver(user2);
        vm.stopPrank();

        assertEq(bridge.feeReceiver(), user2);
    }

    function test_setMultiplePermissionsToWithdraw() public {
        vm.prank(bridgeSigner);
        // create NFT
        address newNFT = bridge.createERC721({
            uri: "ipfs://uriz/",
            name: "TestNFT",
            symbol: "TNFT"
        });

        // setup NFT
        vm.prank(deployer);
        bridge.setNFTDetails({
            isActive: true,
            nftContractAddress: newNFT,
            feeTokenAddress: address(feeToken),
            depositFeeAmount: depositFee,
            withdrawFeeAmount: withdrawFee
        });

        // mint NFT to bridge
        vm.prank(bridgeSigner);
        bridge.mintERC721({
            nftAddress: newNFT,
            to: address(bridge),
            tokenId: 0
        });
        vm.prank(bridgeSigner);
        bridge.mintERC721({
            nftAddress: newNFT,
            to: address(bridge),
            tokenId: 1
        });

        // set multipermission to withdraw to user1
        uint[] memory userNFTs = new uint[](2);
        userNFTs[0] = 0;
        userNFTs[1] = 1;
        address[] memory userNFTsAddresses = new address[](2);
        userNFTsAddresses[0] = user1;
        userNFTsAddresses[1] = user1;

        vm.prank(bridgeSigner);
        bridge.setMultiplePermissionsToWithdraw({
            contractAddress: newNFT,
            owners: userNFTsAddresses,
            tokenIds: userNFTs
        });
        // withdraw with user1
        vm.prank(user1);
        vm.expectEmit(address(bridge));
        emit NFTWithdrawn(address(newNFT), user1, 0, withdrawFee);
        emit NFTWithdrawn(address(newNFT), user1, 1, withdrawFee);
        bridge.withdrawMultipleERC721(address(newNFT), userNFTs);

        
    }

    function test_fee() public {
        // deploy 2 ERC20 tokens
        vm.startPrank(deployer);

        base_erc20 feeToken2 = new base_erc20();
        base_erc20 feeToken3 = new base_erc20();
        // enable ERC20
        bridge.setERC20Details({
            isActive: true,
            erc20ContractAddress: address(feeToken2)
        });
        bridge.setERC20Details({
            isActive: true,
            erc20ContractAddress: address(feeToken3)
        });
        // deploy 2 ERC721 token
        base_erc721 nftToken2 = new base_erc721(
            "TestNFT",
            "TNFT"
        );
        base_erc721 nftToken3 = new base_erc721(
            "TestNFT",
            "TNFT"
        );
        // configure them as feeToken for NFT
        bridge.setNFTDetails({
            isActive: true,
            nftContractAddress: address(nftToken2),
            feeTokenAddress: address(feeToken2),
            depositFeeAmount: depositFee,
            withdrawFeeAmount: withdrawFee
        });
        bridge.setNFTDetails({
            isActive: true,
            nftContractAddress: address(nftToken3),
            feeTokenAddress: address(feeToken3),
            depositFeeAmount: depositFee,
            withdrawFeeAmount: withdrawFee
        });


        // mint 1 NFT to the user1
        nftToken2.safeMintTo(user1, 0);
        nftToken2.safeMintTo(user1, 1);
        nftToken3.safeMintTo(user1, 0);
        vm.stopPrank();
        uint snapshot = vm.snapshot(); // (. ❛ ᴗ ❛.)
        // test1: user will hit FeeTokenInsufficentBalance
        vm.startPrank(user1);

        feeToken2.approve(address(bridge), type(uint).max);
        feeToken3.approve(address(bridge), type(uint).max);
        nftToken2.setApprovalForAll(address(bridge), true);
        nftToken3.setApprovalForAll(address(bridge), true);
        uint[] memory userTokens = new uint[](2);
        // no need to test same ID, it will revert as those are transferred one by one
        userTokens[0] = 0;
        userTokens[1] = 1;
        vm.expectRevert(ERC721Bridge.FeeTokenInsufficentBalance.selector);
        bridge.depositMultipleERC721{value: ethDepositFee*userTokens.length}(address(nftToken2), address(feeToken2), userTokens);
        vm.stopPrank();
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

        //test2: user will hit FeeTokenNotApproved
        // send user1 the ERC20 fee amount
        vm.prank(deployer);
        feeToken2.transfer(user1, depositFee*2); // 2 NFTs
        vm.prank(deployer);
        feeToken3.transfer(user1, depositFee*2); // 2 NFTs

        vm.startPrank(user1);
        nftToken2.setApprovalForAll(address(bridge), true);
        nftToken3.setApprovalForAll(address(bridge), true);
        vm.expectRevert(abi.encodeWithSelector(ERC721Bridge.FeeTokenNotApproved.selector, address(feeToken2), depositFee*2));
        bridge.depositMultipleERC721{value: ethDepositFee*userTokens.length}(address(nftToken2), address(feeToken2), userTokens);

        vm.stopPrank();
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
        // set 0 fee
        vm.prank(deployer);
        bridge.setNFTDetails({
            isActive: true,
            nftContractAddress: address(nftToken2),
            feeTokenAddress: address(feeToken2),
            depositFeeAmount: 0,
            withdrawFeeAmount: 0
        });

        vm.startPrank(user1);
        nftToken2.setApprovalForAll(address(bridge), true);
        feeToken2.approve(address(bridge), type(uint).max);
        bridge.depositMultipleERC721{value: ethDepositFee*userTokens.length}(address(nftToken2), address(feeToken2), userTokens);

        vm.stopPrank();
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
        // disable bridge fees
        vm.prank(deployer);
        bridge.setFeeStatus(false);
        // set 0 fee
        vm.prank(deployer);
        bridge.setNFTDetails({
            isActive: true,
            nftContractAddress: address(nftToken2),
            feeTokenAddress: address(feeToken2),
            depositFeeAmount: 0,
            withdrawFeeAmount: 0
        });

        vm.startPrank(user1);
        nftToken2.setApprovalForAll(address(bridge), true);
        feeToken2.approve(address(bridge), type(uint).max);
        bridge.depositMultipleERC721{value: ethDepositFee*userTokens.length}(address(nftToken2), address(feeToken2), userTokens);
    }

    function test_eth_fee() public {
    // user1 cannot deposit without paying the ETH fee
        vm.prank(user1);
        vm.expectRevert(abi.encodePacked(ERC721Bridge.InsufficentETHAmountForFee.selector, ethDepositFee));
        bridge.depositSingleERC721{value: 0}(address(nftToken), 0);
    
    // user1 cannot deposit with a wrong ETH fee
        // lower
        vm.prank(user1);
        vm.expectRevert(abi.encodePacked(ERC721Bridge.InsufficentETHAmountForFee.selector, ethDepositFee));
        bridge.depositSingleERC721{value: ethDepositFee/2}(address(nftToken), 0);
        // higher
        vm.prank(user1);
        vm.expectRevert(abi.encodePacked(ERC721Bridge.InsufficentETHAmountForFee.selector, ethDepositFee));
        bridge.depositSingleERC721{value: ethDepositFee*2}(address(nftToken), 0);

    // increase fee to 0.001 ETH
        vm.prank(deployer);
        ethDepositFee = 0.001 ether;
        bridge.setETHFee(true, ethDepositFee);

    // user1 cannot multiple deposit without paying the ETH fee
        vm.prank(deployer);
        nftToken.safeMint(user1);
        uint[] memory userNFTs = new uint[](2);
        userNFTs[0] = 0;
        userNFTs[1] = 3;

        vm.startPrank(user1);
        // approve feeToken and NFTs
        feeToken.approve(address(bridge), type(uint).max);
        nftToken.setApprovalForAll(address(bridge), true);

        vm.expectRevert(abi.encodePacked(ERC721Bridge.InsufficentETHAmountForFee.selector, ethDepositFee*userNFTs.length));
        bridge.depositMultipleERC721{value: 0}(address(nftToken), address(feeToken), userNFTs);

    // user1 cannot multiple deposit with a wrong ETH fee
        // lower
        vm.expectRevert(abi.encodePacked(ERC721Bridge.InsufficentETHAmountForFee.selector, ethDepositFee*userNFTs.length));
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTs.length/2}(address(nftToken), address(feeToken), userNFTs);
        // higher
        vm.expectRevert(abi.encodePacked(ERC721Bridge.InsufficentETHAmountForFee.selector, ethDepositFee*userNFTs.length));
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTs.length*2}(address(nftToken), address(feeToken), userNFTs);

    // disable fees
        vm.stopPrank();
        vm.prank(deployer);
        bridge.setETHFee(false, ethDepositFee);
        
        uint snapshot = vm.snapshot(); // (. ❛ ᴗ ❛.)

        vm.startPrank(user1);
        bridge.depositSingleERC721{value: 0}(address(nftToken), 0);
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
        bridge.depositMultipleERC721{value: 0}(address(nftToken), address(feeToken), userNFTs);
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ

    // enable fees but set 0 amount
        vm.stopPrank();
        vm.prank(deployer);
        bridge.setETHFee(true, 0);

        snapshot = vm.snapshot(); // (. ❛ ᴗ ❛.)

        vm.startPrank(user1);
        bridge.depositSingleERC721{value: 0}(address(nftToken), 0);
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
        bridge.depositMultipleERC721{value: 0}(address(nftToken), address(feeToken), userNFTs);
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
    }

    function test_multiple_withdraw_fee() public {
        // mint nft to user
        vm.prank(deployer);
        nftToken.safeMint(user1);

        // set 1 token as fee
        vm.prank(deployer);
        bridge.setTokenFees({
            active: true,
            nftAddress: address(nftToken),
            depositFee: 1 ether,
            withdrawFee: 1 ether
        });
        withdrawFee = 1 ether;

        // create nft list
        uint[] memory userNFTs = new uint[](2);
        userNFTs[0] = 0;
        userNFTs[1] = 3;

        vm.startPrank(user1);

        // aprove fee token and NFTs
        feeToken.approve(address(bridge), type(uint).max);
        nftToken.setApprovalForAll(address(bridge), true);

        uint totalTokenFee = depositFee*userNFTs.length;
        uint totalEthFee = ethDepositFee*userNFTs.length;

        uint userTokenBalance      = feeToken.balanceOf(user1);
        uint userNFTBalance        = nftToken.balanceOf(user1);
        uint feeReceiverEthBalance = feeReceiver.balance;

        vm.expectEmit(address(bridge));
        emit NFTDeposited(address(nftToken), user1, userNFTs[0], depositFee);
        emit NFTDeposited(address(nftToken), user1, userNFTs[1], depositFee);
        emit TokenFeeCollected(address(feeToken), totalTokenFee);
        emit ETHFeeCollected(totalEthFee);
        bridge.depositMultipleERC721{value: ethDepositFee*userNFTs.length}(address(nftToken), address(feeToken), userNFTs);

        assertEq(feeToken.balanceOf(user1), userTokenBalance - totalTokenFee);
        assertEq(nftToken.balanceOf(user1), userNFTBalance - userNFTs.length);
        assertEq(feeReceiver.balance, feeReceiverEthBalance + totalEthFee);

        // set permission to withdraw
        vm.stopPrank();
        address[] memory userNFTsAddresses = new address[](2);
        userNFTsAddresses[0] = user1;
        userNFTsAddresses[1] = user1;

        vm.prank(bridgeSigner);
        bridge.setMultiplePermissionsToWithdraw({
            contractAddress: address(nftToken),
            owners: userNFTsAddresses,
            tokenIds: userNFTs
        });

        vm.startPrank(user1);

        userTokenBalance      = feeToken.balanceOf(user1);
        userNFTBalance        = nftToken.balanceOf(user1);

        //emit TokenFeeCollected(address(feeToken), totalTokenFee);

        // if we pass an empty array the call should revert
        uint[] memory emptyArray = new uint[](0);
        vm.expectRevert(ERC721Bridge.NoNFTsToWithdraw.selector);
        bridge.withdrawMultipleERC721(address(nftToken), emptyArray);

        // if we pass an array too big the call should revert
        uint[] memory bigArray = new uint[](51);
        vm.expectRevert(abi.encodePacked(ERC721Bridge.TooManyNFTsToWithdraw.selector, uint(50)));
        bridge.withdrawMultipleERC721(address(nftToken), bigArray);

        // snapshot
        uint snapshot = vm.snapshot(); // (. ❛ ᴗ ❛.)
        vm.stopPrank();
        vm.prank(deployer);
        // disable bridge
        bridge.setBridgeStatus(false);
        vm.prank(user1);
        vm.expectRevert(ERC721Bridge.BridgeIsPaused.selector);
        bridge.withdrawMultipleERC721(address(nftToken), userNFTs);
        vm.revertTo(snapshot); // ᕦ(ò_óˇ)ᕤ
        
        // withdraw multiple NFTs
        vm.expectEmit(address(bridge));
        emit NFTWithdrawn(address(nftToken), user1, userNFTs[0], withdrawFee);
        emit NFTWithdrawn(address(nftToken), user1, userNFTs[1], withdrawFee);

        vm.prank(user1);
        bridge.withdrawMultipleERC721(address(nftToken), userNFTs);

    }

    function test_Bridge_script() external {
        DeployAllAndSetBridge script = new DeployAllAndSetBridge();
        script.run();
    }
}
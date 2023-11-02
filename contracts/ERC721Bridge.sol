// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { base_erc721 } from "./base_erc721.sol"; // TODO: to be completed

/**
 * @title ERC721Bridge
 * @author Krakovia - t.me/karola96
 * @notice This contract is an erc721 bridge with optional fees and manual permission to withdraw
 */
contract ERC721Bridge is ERC721Holder, AccessControl, ReentrancyGuard {

    bytes32 public constant OPERATOR = keccak256("OPERATOR");
    bytes32 public constant BRIDGE = keccak256("BRIDGE");

    bool public isOnline;
    bool public feeActive;
    bool public ethFeeActive;
    address public feeReceiver;
    uint public maxNFTsPerTx = 50;
    uint public ethDepositFee;

    mapping(address => NFTContracts) public permittedNFTs;
    mapping(address => ERC20Tokens) public permittedERC20s;
    mapping(address => mapping(uint => NFT)) public nftListPerContract;
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
        bool canBeWithdrawn;
        address owner;
    }

    /**
     * @notice constructor will set the roles and the bridge fee
     * @param _bridgeSigner address of the signer of the bridge
     * @param _feeReceiver address of the fee receiver
     * @param _operator address of the operator
     */
    constructor(address _bridgeSigner, address _feeReceiver, address _operator) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR, _operator);
        _setupRole(BRIDGE, _bridgeSigner);
        feeReceiver = _feeReceiver;
    }

    // bridge
    error BridgeIsPaused();
    error InvalidMaxNFTsPerTx();
    error ETHTransferError();
    // fees
    error FeeTokenNotApproved(address tokenToApprove, uint amount);
    error FeeTokenInsufficentBalance();
    error InsufficentETHAmountForFee(uint ethRequired);
    // nft
    error NFTNotOwnedByYou();
    error NoNFTsToDeposit();
    error TooManyNFTsToDeposit(uint maxNFTsPerTx);
    error NoNFTsToWithdraw();
    error TooManyNFTsToWithdraw(uint maxNFTsPerTx);
    error NFTContractNotActive();
    error NFTNotUnlocked();
    // tokens
    error ERC20ContractNotActive();
    error ERC20TransferError();

    // bridge
    event BridgeIsOnline(bool active);
    event BridgeFeesPaused(bool active);
    // fees
    event FeesSet(bool active, address indexed nftAddress, address indexed tokenAddress, uint depositFee, uint withdrawFee);
    event FeeReceiverSet(address receiver);
    event ETHFeeSet(bool active, uint amount);
    event TokenFeeCollected(address indexed tokenAddress, uint amount);
    event ETHFeeCollected(uint amount);
    // nft
    event NFTDeposited(address indexed contractAddress, address owner, uint256 tokenId, uint256 fee);
    event NFTWithdrawn(address indexed contractAddress, address owner, uint256 tokenId, uint fee);
    event NFTDetailsSet(bool isActive, address nftContractAddress, address feeTokenAddress, uint feeAmount);
    event NFTUnlocked(address indexed contractAddress, address owner, uint256 tokenId);
    // tokens
    event ERC20DetailsSet(bool isActive, address erc20ContractAddress);

    // -----------------------------------------
    // -----------------------------------------
    // -----------------------------------------

    /**
     * @notice max amount of NFTs that can be used in a tx
     * @dev only operator can call this
     * @param maxNFTsPerTx_ uint of the max amount of NFTs
     */
    function setMaxNFTsPerTx(uint maxNFTsPerTx_) external onlyRole(OPERATOR) {
        maxNFTsPerTx = maxNFTsPerTx_;
        if(maxNFTsPerTx == 0 || maxNFTsPerTx > 50) revert InvalidMaxNFTsPerTx();
    }

    /**
     * @notice set the bridge status
     * @dev only operator can call this
     * @param active bool to activate or deactivate the bridge
     */
    function setBridgeStatus(bool active) external onlyRole(OPERATOR) {
        isOnline = active;
        emit BridgeIsOnline(active);
    }

    /**
     * @notice set the bridge fee statys
     * @dev only operator can call this
     * @param active bool to activate or deactivate the bridge
     */
    function setFeeStatus(bool active) external onlyRole(OPERATOR) {
        feeActive = active;
        emit BridgeFeesPaused(active);
    }

    /**
     * @notice set the ETH fee status
     * @dev only operator can call this
     * @param status bool to activate or deactivate the fees
     * @param amount uint to set the fee amount
     */
    function setETHFee(bool status, uint amount) external onlyRole(OPERATOR) {
        ethFeeActive = status;
        ethDepositFee = amount;
        emit ETHFeeSet(status, amount);
    }

    /**
     * @notice set the fees for the ERC20 tokens
     * @dev only operator can call this
     * @param active bool to activate or deactivate the fees
     * @param nftAddress address of the NFT Token
     * @param depositFee uint to set the deposit fee for the bridge
     * @param withdrawFee uint to set the withdraw fee for the bridge
     */
    function setTokenFees(bool active, address nftAddress, uint depositFee, uint withdrawFee) external onlyRole(OPERATOR) {
        NFTContracts storage nft = permittedNFTs[nftAddress];
        nft.isActive = active;
        nft.feeDepositAmount = depositFee;
        nft.feeWithdrawAmount = withdrawFee;
        emit FeesSet(active, nftAddress, nft.feeTokenAddress, depositFee, withdrawFee);
    }

    /**
     * @notice set the bridgeFee receiver
     * @dev only operator can call this
     * @param receiver address of the fee receiver
     */
    function setFeeReceiver(address receiver) external onlyRole(OPERATOR) {
        feeReceiver = receiver;
        emit FeeReceiverSet(receiver);
    }

    /**
     * @notice set the settings of an NFT address
     * @dev only operator can call this
     * @param isActive bool to activate or deactivate the NFT contract
     * @param nftContractAddress address of the NFT contract
     * @param feeTokenAddress address of the token to pay the fee
     * @param depositFeeAmount uint of the deposit fee amount
     * @param withdrawFeeAmount uint of the withdraw fee amount
     */
    function setNFTDetails(bool isActive, address nftContractAddress, address feeTokenAddress, uint depositFeeAmount, uint withdrawFeeAmount) external onlyRole(OPERATOR) {
        NFTContracts storage nft = permittedNFTs[nftContractAddress];
        nft.isActive = isActive;
        nft.contractAddress = nftContractAddress;
        nft.feeTokenAddress = feeTokenAddress;
        nft.feeDepositAmount = depositFeeAmount;
        nft.feeWithdrawAmount = withdrawFeeAmount;
        emit NFTDetailsSet(isActive, nftContractAddress, feeTokenAddress, depositFeeAmount);
    }

    /**
     * @notice set the settings of an ERC20 address
     * @dev only operator can call this
     * @param isActive bool to activate or deactivate the ERC20 contract
     * @param erc20ContractAddress address of the ERC20 contract
     */
    function setERC20Details(bool isActive, address erc20ContractAddress) external onlyRole(OPERATOR) {
        ERC20Tokens storage erc20 = permittedERC20s[erc20ContractAddress];
        erc20.isActive = isActive;
        erc20.contractAddress = erc20ContractAddress;
        emit ERC20DetailsSet(isActive, erc20ContractAddress);
    }

    /**
     * @notice the oracle assign the withdraw option to users
     * @dev only oracle can call this
     * @param contractAddress address of the NFT contract
     * @param owner address of the owner of the NFT
     * @param tokenId uint of the NFT id
     */
    function setPermissionToWithdraw(address contractAddress, address owner, uint tokenId) public onlyRole(BRIDGE) {
        NFT storage nft = nftListPerContract[contractAddress][tokenId];
        nft.owner = owner;
        nft.canBeWithdrawn = true;
        emit NFTUnlocked(contractAddress, owner, tokenId);
    }

    function setMultiplePermissionsToWithdraw(address contractAddress, address[] memory owners, uint[] memory tokenIds) external onlyRole(BRIDGE) {
        for (uint i = 0; i < owners.length; i++) {
            setPermissionToWithdraw(contractAddress, owners[i], tokenIds[i]);
        }
    }

    // -----------------------------------------

    /**
     * @notice deposit an ERC721 token to the bridge
     * @param nftAddress address of the NFT contract
     * @param tokenId uint of the NFT id
     */
    function depositSingleERC721(address nftAddress, uint tokenId) external payable nonReentrant {
        // storage to access NFT Contract, NFT and erc20 details
        NFTContracts storage nftContract = permittedNFTs[nftAddress];
        NFT storage nft = nftListPerContract[nftAddress][tokenId];
        ERC20Tokens storage erc20Token = permittedERC20s[nftContract.feeTokenAddress];

        // bridge must be active
        if(!isOnline) revert BridgeIsPaused();
        // NFT contract must be allowed to use bridge
        if (!nftContract.isActive) revert NFTContractNotActive();
        // ERC20 token must be allowed to use bridge
        if (!erc20Token.isActive) revert ERC20ContractNotActive();
        // NFT must be owned by msg.sender - @audit can be removed for gas opt
        if(IERC721(nftAddress).ownerOf(tokenId) != msg.sender) revert NFTNotOwnedByYou();
        // check if fees are active and > 0
        if (ethFeeActive && ethDepositFee > 0) {
            // check if user has enough ETH to pay for the bridge
            if(msg.value != ethDepositFee) revert InsufficentETHAmountForFee(ethDepositFee);
            // send ETH fee to feeReceiver
            (bool success,) = feeReceiver.call{value: msg.value}("");
            emit ETHFeeCollected(msg.value);
            if (!success) revert ETHTransferError();
        }

        uint bridgeCost;
        uint feeAmount = nftContract.feeDepositAmount;
        address feeTokenAddress = nftContract.feeTokenAddress;
        // if Fees are active, we add the fee to the bridge cost
        if (feeActive && feeAmount > 0) {
            bridgeCost = takeFees(feeTokenAddress, feeAmount, 1);
        }

        // set NFT details
        nft.owner = msg.sender;
        // in case it's already been bridged
        nft.canBeWithdrawn = false;
        
        // transfer NFT to contract
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        // send event to oracle
        emit NFTDeposited(nftAddress, msg.sender, tokenId, bridgeCost);
    }

    /**
     * @notice deposit multiple ERC721 tokens to the bridge
     * @param nftAddress address of the NFT contract
     * @param tokenAddress address of the ERC20 token to pay the fee
     * @param tokenIds uint[] of the NFT ids
     */
    function depositMultipleERC721(address nftAddress, address tokenAddress, uint[] memory tokenIds) external payable nonReentrant {
        uint nftQuantity = tokenIds.length;
        // storage to access NFT Contract, NFT and erc20 details
        NFTContracts storage nftContract = permittedNFTs[nftAddress];
        ERC20Tokens storage erc20Token = permittedERC20s[tokenAddress];

        // bridge must be active
        if(!isOnline) revert BridgeIsPaused();
        // NFT contract must be allowed to use bridge
        if (!nftContract.isActive) revert NFTContractNotActive();
        // ERC20 token must be allowed to use bridge
        if (!erc20Token.isActive) revert ERC20ContractNotActive();
        // check if fees are active and > 0
        if(ethFeeActive && ethDepositFee > 0) {
            // check if user has enough ERC20 to pay for the bridge
            if(msg.value != ethDepositFee * nftQuantity) revert InsufficentETHAmountForFee(ethDepositFee * nftQuantity);
            // send ETH fee to feeReceiver
            (bool success,) = feeReceiver.call{value: msg.value}("");
            emit ETHFeeCollected(msg.value);
            if (!success) revert ETHTransferError();
        }
        // user should deposit at least 1 NFT
        if(nftQuantity == 0) revert NoNFTsToDeposit();
        // user should deposit less than the max amount of NFTs per tx
        if(nftQuantity > maxNFTsPerTx) revert TooManyNFTsToDeposit(maxNFTsPerTx);

        uint bridgeCost;
        uint fees = nftContract.feeDepositAmount;
        address feeTokenAddress = nftContract.feeTokenAddress;

        // if Fees are active, we add the fee to the bridge cost
        if (feeActive && fees != 0) {
            bridgeCost = fees * nftQuantity;
            if (IERC20(feeTokenAddress).balanceOf(msg.sender) < bridgeCost) {
                revert FeeTokenInsufficentBalance();
            }
            if (IERC20(feeTokenAddress).allowance(msg.sender, address(this)) < bridgeCost) {
                revert FeeTokenNotApproved(feeTokenAddress, bridgeCost);
            }
            IERC20(tokenAddress).transferFrom(msg.sender, feeReceiver, bridgeCost);
        }

        // loop through tokenIds
        for (uint i = 0; i < nftQuantity;) {
            // storage to access NFT details
            NFT storage nft = nftListPerContract[nftAddress][tokenIds[i]];

            // set NFT details
            nft.owner = msg.sender;
            // in case it's already been bridged
            nft.canBeWithdrawn = false;

            // transfer NFT to contract
            IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenIds[i]);
            // send event to oracle
            emit NFTDeposited(nftAddress, msg.sender, tokenIds[i], bridgeCost / nftQuantity);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice withdraw an ERC721 token from the bridge
     * @dev must be approved from the bridgeSigner first
     * @param nftContractAddress address of the NFT contract
     * @param tokenId uint of the NFT id
     */
    function withdrawSingleERC721(address nftContractAddress, uint tokenId) external nonReentrant {
        // storage to access NFT Contract, NFT and erc20 details
        NFTContracts storage nftContract = permittedNFTs[nftContractAddress];
        NFT storage nft = nftListPerContract[nftContractAddress][tokenId];

        // bridge must be active
        if(!isOnline) revert BridgeIsPaused();
        // NFT contract must be allowed to use bridge
        if (!nftContract.isActive) revert NFTContractNotActive();
        // NFT must be withdrawable
        if (!nft.canBeWithdrawn) revert NFTNotUnlocked();
        // NFT must be owned by msg.sender
        if (nft.owner != msg.sender) revert NFTNotOwnedByYou();

        uint bridgeCost;
        uint feeAmount = nftContract.feeWithdrawAmount;
        address feeTokenAddress = nftContract.feeTokenAddress;
        // if Fees are active, we add the fee to the bridge cost
        if (feeActive && feeAmount != 0) {
            bridgeCost = takeFees(feeTokenAddress, feeAmount, 1);
        }

        // set NFT details
        nft.owner = address(0);
        nft.canBeWithdrawn = false;

        // transfer NFT to user
        IERC721(nftContractAddress).transferFrom(address(this), msg.sender, tokenId);
        emit NFTWithdrawn(nftContractAddress, msg.sender, tokenId, bridgeCost);
    }

    /**
     * @notice withdraw multiple ERC721 tokens from the bridge
     * @dev must be approved from the bridgeSigner first
     * @param contractAddress address of the NFT contract
     * @param tokenIds uint[] of the NFT ids
     */
    function withdrawMultipleERC721(address contractAddress, uint[] memory tokenIds) external nonReentrant {
        // storage to access NFT Contract, NFT and erc20 details
        NFTContracts storage nftContract = permittedNFTs[contractAddress];

        // bridge must be active
        if(!isOnline) revert BridgeIsPaused();
        // NFT contract must be allowed to use bridge
        if(!nftContract.isActive) revert NFTContractNotActive();

        uint nftQuantity = tokenIds.length;
        if(nftQuantity == 0) revert NoNFTsToWithdraw();
        if(nftQuantity > maxNFTsPerTx) revert TooManyNFTsToWithdraw(maxNFTsPerTx);
        uint bridgeCost;
        uint fees = nftContract.feeWithdrawAmount;
        address feeTokenAddress = nftContract.feeTokenAddress;
        // apply Fees if active
        if (feeActive && fees != 0) {
            bridgeCost = takeFees(feeTokenAddress, fees, nftQuantity);
        }

        // loop through tokenIds
        for (uint i = 0; i < tokenIds.length; i++) {
            // storage to access NFT details
            NFT storage nft = nftListPerContract[contractAddress][tokenIds[i]];
            // NFT must be withdrawable
            if (!nft.canBeWithdrawn) revert NFTNotUnlocked();
            // NFT must be owned by msg.sender
            if (nft.owner != msg.sender) revert NFTNotOwnedByYou();

            // set NFT details
            nft.owner = address(0);
            nft.canBeWithdrawn = false;

            // transfer NFT to user
            IERC721(contractAddress).transferFrom(address(this), msg.sender, tokenIds[i]);
            emit NFTWithdrawn(contractAddress, msg.sender, tokenIds[i], bridgeCost / nftQuantity);
        }
    }

    /**
     * @notice take fees from the user
     * @param feeTokenAddress address of the token to take fees in
     * @param fees amount of fees to take
     * @param quantity number of NFTs to bridge
     * @return uint of the total cost of the bridge
     */
    function takeFees(address feeTokenAddress, uint fees, uint quantity) private returns (uint) {
        uint bridgeCost = fees * quantity;
        if (IERC20(feeTokenAddress).balanceOf(msg.sender) < bridgeCost) {
            revert FeeTokenInsufficentBalance();
        }
        if (IERC20(feeTokenAddress).allowance(msg.sender, address(this)) < bridgeCost) {
            revert FeeTokenNotApproved(feeTokenAddress, bridgeCost);
        }
        bool success = IERC20(feeTokenAddress).transferFrom(msg.sender, feeReceiver, bridgeCost);
        emit TokenFeeCollected(feeTokenAddress, bridgeCost);
        if (!success) {
            revert ERC20TransferError();
        }
        return bridgeCost;
    }

    /**
     * @notice get the fee token address and amount of fees for a given NFT contract
     * @param contractAddress nft contract address
     * @return address of the fee token and amount of fees
     */
    function getDepositFeeAddressAndAmount(address contractAddress) external view returns (address,uint) {
        NFTContracts storage nftContract = permittedNFTs[contractAddress];
        return (nftContract.feeTokenAddress, nftContract.feeDepositAmount);
    }

    // -----------------------------------------
    // ERC721 bridge functions

    /**
     * @notice create a new ERC721 token owned by the bridge
     * @param uri the uri of the new NFT
     * @param name the name of the new NFT
     * @param symbol the symbol of the new NFT
     * @return nftAddress address of the new NFT contract
     */
    function createERC721(string calldata uri, string calldata name, string calldata symbol) public onlyRole(BRIDGE) returns(address nftAddress) {
        base_erc721 newERC721 = new base_erc721(name, symbol);
        newERC721.setBaseURI(uri);
        emit NFTDetailsSet(true, address(newERC721), address(0), 0);
        return address(newERC721);
    }

    /**
     * @notice mint an ERC721 token to an user
     * @dev only bridge signer can call this
     * @param nftAddress NFT contract address
     * @param to address of the user to mint to
     * @param tokenId uint of the NFT id
     */
    function mintERC721(address nftAddress, address to, uint tokenId) public onlyRole(BRIDGE) {
        base_erc721(nftAddress).safeMintTo(to, tokenId);
    }

    /**
     * @notice set the permission to withdraw and create an ERC721 token
     * @param owner address of the user to mint to
     * @param tokenId uint of the NFT id
     * @param uri string of the NFT uri metadata
     * @param name string of the NFT name
     * @param symbol string of the NFT symbol
     * @return nftAddress address of the new NFT contract
     */
    function setPermissionToWithdrawAndCreateERC721(
        address owner, uint tokenId, string calldata uri,
        string calldata name, string calldata symbol)
        external onlyRole(BRIDGE) returns(address nftAddress) {

        nftAddress = createERC721(uri, name, symbol);
        mintERC721(nftAddress, address(this), tokenId);
        setPermissionToWithdraw(nftAddress, owner, tokenId);
    }
}
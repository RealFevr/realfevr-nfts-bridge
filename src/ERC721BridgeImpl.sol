// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { base_erc721 } from "./base_erc721.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title ERC721Bridge
 * @author Krakovia - t.me/karola96
 * @notice This contract is an erc721 bridge with optional fees
 */
contract ERC721BridgeImpl is ERC721Holder, AccessControlUpgradeable, ReentrancyGuardUpgradeable, UUPSUpgradeable {

    bytes32 public OPERATOR;
    bytes32 public BRIDGE;

    bool public isOnline;
    bool public feeActive;
    address public feeReceiver;
    uint public maxNFTsPerTx;

    mapping(uint chainId => ChainETHFee)     public ethDepositFee;
    mapping(address => NFTContracts)         public permittedNFTs;
    mapping(address => ERC20Tokens)          public permittedERC20s;
    mapping(string key => bool used)         public withdrawUniqueKeys;
    mapping(string key => bool used)         public mintUniqueKeys;
    mapping(uint chainId => bool supported)  public supportedChains;

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
    error BridgeIsPaused();                         // when the bridge is paused
    error InvalidMaxNFTsPerTx();                    // when the max amount of NFTs per tx is invalid
    error ETHTransferError();                       // when the ETH transfer fails
    // fees
    error FeeTokenNotApproved(address tokenToApprove, uint amount); // when the fee token is not approved
    error FeeTokenInsufficentBalance();                  // when the user doesn't have enough fee token balance
    error InsufficentETHAmountForFee(uint ethRequired);  // when the user doesn't have enough ETH to pay the fee
    // nft
    error NFTNotOwnedByYou();                       // when the NFT is not owned by the user
    error NoNFTsToDeposit();                        // when the user tries to deposit 0 NFTs
    error TooManyNFTsToDeposit(uint maxNFTsPerTx);  // when the user tries to deposit more than the max amount of NFTs per tx
    error NoNFTsToWithdraw();                       // when the user tries to withdraw 0 NFTs
    error TooManyNFTsToWithdraw(uint maxNFTsPerTx); // when the user tries to withdraw more than the max amount of NFTs per tx
    error NFTContractNotActive();                   // when the NFT contract is not active
    error NFTNotUnlocked();                         // when the NFT is not unlocked
    // tokens
    error ERC20ContractNotActive();                 // when the ERC20 contract is not active
    error ERC20TransferError();                     // when the ERC20 transfer fails
    error UniqueKeyUsed();                          // when the unique key is already used

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
    event NFTDetailsSet(bool isActive, address nftContractAddress, address feeTokenAddress, uint feeAmount);
    event ERC721Minted(address indexed nftAddress, address indexed to, uint256 tokenId, string uniqueKey);
    // tokens
    event ERC20DetailsSet(bool isActive, address erc20ContractAddress);

    // impl v2 storage
    bool private _multiDeposit;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /**
     * @notice initialize will set the role addresses
     * @param _bridgeSigner address of the signer of the bridge
     * @param _feeReceiver address of the fee receiver
     * @param _operator address of the operator
     */
    function initialize(address _bridgeSigner, address _feeReceiver, address _operator) external initializer {
        bool success;
        OPERATOR = keccak256("OPERATOR");
        BRIDGE = keccak256("BRIDGE");
        maxNFTsPerTx = 50;
        success = _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        success = _grantRole(OPERATOR, _operator);
        success = _grantRole(BRIDGE, _bridgeSigner);
        feeReceiver = _feeReceiver;
    }

    // -----------------------------------------
    // -----------------------------------------
    // -----------------------------------------

    /**
     * @notice set the supported chain
     * @dev only operator can call this
     * @param chainId uint of the chain id
     * @param status bool to enable or disable the chain id
     */
    function setSupportedChain(uint chainId, bool status) external onlyRole(OPERATOR) {
        supportedChains[chainId] = status;
    }

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
     * @notice set the bridge fee status
     * @dev only operator can call this
     * @param active bool to activate or deactivate the bridge fee
     */
    function setFeeStatus(bool active) external onlyRole(OPERATOR) {
        feeActive = active;
        emit BridgeFeesPaused(active);
    }

    /**
     * @notice set the ETH fee on specified chain id
     * @dev only operator can call this
     * @param chainId uint of the chain id
     * @param status bool to activate or deactivate the fees
     * @param amount uint of the fee amount
     */
    function setETHFee(uint chainId, bool status, uint amount) external onlyRole(OPERATOR) {
        ethDepositFee[chainId].isActive = status;
        ethDepositFee[chainId].amount = amount;
        emit ETHFeeSet(chainId, status, amount);
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

    // -----------------------------------------

    /**
     * @notice deposit an ERC721 token to the bridge
     * @param nftAddress address of the NFT contract
     * @param tokenId uint of the NFT id
     */
    function depositSingleERC721(address nftAddress, uint tokenId, uint targetChainId) public payable {
        // storage to access NFT Contract, NFT and erc20 details
        NFTContracts storage nftContract = permittedNFTs[nftAddress];
       
        ERC20Tokens storage erc20Token = permittedERC20s[nftContract.feeTokenAddress];
        ChainETHFee storage ethFee = ethDepositFee[targetChainId];
        uint ethFeeAmount = ethFee.amount;

        // bridge must be active
        if(!isOnline) revert BridgeIsPaused();
        // NFT contract must be allowed to use bridge
        if (!nftContract.isActive) revert NFTContractNotActive();
        // ERC20 token must be allowed to use bridge
        if (!erc20Token.isActive) revert ERC20ContractNotActive();
        // NFT must be owned by msg.sender
        if(IERC721(nftAddress).ownerOf(tokenId) != msg.sender) revert NFTNotOwnedByYou();
        // chain id must be supported
        if(!supportedChains[targetChainId]) revert ChainNotSupported();


        // check if fees are active and > 0 and it's not a multiDeposit
        if (ethFee.isActive && ethFeeAmount > 0 && !_multiDeposit) {
            // check if user has enough ETH to pay for the bridge
            if(msg.value != ethFeeAmount) revert InsufficentETHAmountForFee(ethFeeAmount);
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
        
        // transfer NFT to contract
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        // send event to oracle
        emit NFTDeposited(nftAddress, msg.sender, tokenId, bridgeCost, targetChainId);
    }

    function depositMultipleERC721(address[] calldata nftAddress, uint[] calldata tokenIds, uint targetChainId) external payable nonReentrant {
            // check if user has enough ETH to pay for the bridge
            uint _ethFeeAmount = ethDepositFee[targetChainId].amount;
            uint _nftLength = nftAddress.length;
            if(msg.value != _ethFeeAmount * _nftLength) revert InsufficentETHAmountForFee(_ethFeeAmount * _nftLength);
        // we handle fees here
        _multiDeposit = true;
        (bool success,) = feeReceiver.call{value: msg.value}("");
            emit ETHFeeCollected(msg.value);
            if (!success) revert ETHTransferError();
        // for each NFT, call depositSingleERC721
        for(uint i = 0; i < _nftLength; i++) {
            depositSingleERC721(nftAddress[i], tokenIds[i], targetChainId);
        }
        _multiDeposit = false;
    }

    /**
     * @notice withdraw an ERC721 token from the bridge
     * @dev only bridgeSigner can call this
     * @param to address of the user to withdraw to
     * @param nftContractAddress address of the NFT contract
     * @param tokenId uint of the NFT id
     */
    function withdrawSingleERC721(address to, address nftContractAddress, uint tokenId, string calldata uniqueKey) public onlyRole(BRIDGE) {
        if(withdrawUniqueKeys[uniqueKey]) revert UniqueKeyUsed();
        withdrawUniqueKeys[uniqueKey] = true;
        // storage to access NFT Contract, NFT and erc20 details
        NFTContracts storage nftContract = permittedNFTs[nftContractAddress];

        // bridge must be active
        if(!isOnline) revert BridgeIsPaused();
        // NFT contract must be allowed to use bridge
        if (!nftContract.isActive) revert NFTContractNotActive();

        // transfer NFT to user
        IERC721(nftContractAddress).transferFrom(address(this), to, tokenId);
        emit NFTWithdrawn(nftContractAddress, to, tokenId, uniqueKey);
    }

    /**
     * @notice withdraw multiple ERC721 tokens from the bridge
     * @dev only bridgeSigner can call this
     * @param to address of the user to withdraw to
     * @param contractAddress address of the NFT contract
     * @param tokenIds uint[] of the NFT ids
     */
    function withdrawMultipleERC721(address to, address contractAddress, uint[] memory tokenIds, string[] calldata uniqueKeys) external onlyRole(BRIDGE) {
        for(uint i = 0; i < tokenIds.length; i++) {
            withdrawSingleERC721(to, contractAddress, tokenIds[i], uniqueKeys[i]);
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
    function createERC721(string calldata uri, string calldata name, string calldata symbol) public onlyRole(OPERATOR) returns(address nftAddress) {
        base_erc721 newERC721 = new base_erc721(name, symbol);
        newERC721.setBaseURI(uri);
        emit NFTDetailsSet(false, address(newERC721), address(0), 0);
        return address(newERC721);
    }

    /**
     * @notice mint an ERC721 token to an user
     * @dev only bridge signer can call this
     * @param nftAddress NFT contract address
     * @param to address of the user to mint to
     * @param tokenId uint of the NFT id
     * @param uniqueKey string of the unique key
     * @param _marketplaceDistributionRates array of uint16 of the marketplace distribution rates
     * @param _marketplaceDistributionAddresses array of address of the marketplace distribution addresses
     */
    function mintERC721(address nftAddress, address to, uint tokenId, string calldata uniqueKey,
    uint16[] calldata _marketplaceDistributionRates, address[] calldata _marketplaceDistributionAddresses) public onlyRole(BRIDGE) {
        // unique key must not be used before
        if(mintUniqueKeys[uniqueKey]) revert UniqueKeyUsed();
        mintUniqueKeys[uniqueKey] = true;
        setMarketplaceDistributions(nftAddress, tokenId, _marketplaceDistributionRates, _marketplaceDistributionAddresses);
        base_erc721(nftAddress).safeMintTo(to, tokenId);
        emit ERC721Minted(nftAddress, to, tokenId, uniqueKey);
    }

    /**
     * @notice Set the marktplace distribution on the NFT contract
     * @dev only bridge signer can call this
     * @param _nftAddress address of the NFT contract
     * @param _tokenId uint of the NFT id
     * @param _marketplaceDistributionRates array of uint16 of the marketplace distribution rates
     * @param _marketplaceDistributionAddresses array of address of the marketplace distribution addresses
     */
    function setMarketplaceDistributions(
        address _nftAddress,
        uint256 _tokenId,
        uint16[] calldata _marketplaceDistributionRates,
        address[] calldata _marketplaceDistributionAddresses
    ) public onlyRole(BRIDGE) {
        require(
            _marketplaceDistributionRates.length == _marketplaceDistributionAddresses.length,
            "MarketplaceDistribution (on bridge): Rates and Addresses length mismatch"
        );
        base_erc721(_nftAddress).setMarketplaceDistributions(_tokenId, _marketplaceDistributionRates, _marketplaceDistributionAddresses);
    }

    /**
     * @notice set the base URI of the NFT contract
     * @dev only operator can call this
     * @param nftAddress address of the NFT contract
     * @param baseURI_ string of the base URI
     */
    function setBaseURI(address nftAddress, string calldata baseURI_) public onlyRole(OPERATOR) {
        base_erc721(nftAddress).setBaseURI(baseURI_);
    }

    /**
     * @notice change the owner of the NFT contract
     * @dev only operator can call this
     * @param nftAddress address of the NFT contract
     * @param newOwner address of the new owner
     */
    function changeOwnerNft(address nftAddress, address newOwner) public onlyRole(OPERATOR) {
        base_erc721(nftAddress).transferOwnership(newOwner);
    }
}
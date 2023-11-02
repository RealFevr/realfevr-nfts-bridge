// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
* 2 Roles Admin and Operator.
* The contract on origin network that hold the BSC tokens cannot release more than X tokens per 24h (managed by operator). Admin has no limit for this. This var should be configurable by admin.
* Contract on the new network can’t mint more then X tokens per 24h. Admin has no limit. This var should be configurable by admin.
* Transfers higher then 24h Limit need to be managed by the admin.
* Possibility to change admin and operator. Pause. Etc.
* Setup fee % and destination address for every transaction from the origin Network.
 */

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { base_erc20 } from "./base_erc20.sol"; // TODO: to be completed
import { console } from "hardhat/console.sol";

interface IERC20 {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
}

/**
 * @title ERC20Bridge
 * @author Krakovia - t.me/karola96
 * @notice This contract is an erc20 bridge with optional fees and manual permission to withdraw
 */
contract ERC20Bridge is AccessControl, ReentrancyGuard {
    
    bytes32 public constant OPERATOR = keccak256("OPERATOR");
    bytes32 public constant BRIDGE   = keccak256("BRIDGE");

    bool    public isOnline;
    bool    public feeActive;
    address public feeReceiver;
    uint    public deployedAt;

    mapping(address tokenAddress => ERC20Contracts)                    public permittedERC20;
    mapping(address user => mapping(address tokenAddress => UserData)) public userERC20Data;

    struct ERC20Contracts {
        bool isActive;
        uint feeDepositAmount;
        uint feeWithdrawAmount;
        uint maxDeposit;
        uint maxWithdraw;
        uint max24hDeposits;
        uint max24hWithdraws;
    }

    struct UserData {
        bool canWithdraw;
        uint depositAmount;
        uint withdrawableAmount;
    }

    /**
     * @notice constructor will set the roles and the bridge fee
     * @param bridgeSigner_ address of the signer of the bridge
     * @param feeReceiver_ address of the fee receiver
     * @param operator_ address of the operator
     */
    constructor(address bridgeSigner_, address feeReceiver_, address operator_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(OPERATOR, operator_);
        _setupRole(BRIDGE, bridgeSigner_);
        feeReceiver = feeReceiver_;
        deployedAt = block.timestamp;
    }

    // bridge
    error BridgeIsPaused();
    // tokens
    error NoTokensToDeposit();
    error TooManyTokensToDeposit(uint maxDeposit);
    error NoTokensToWithdraw();
    error TooManyTokensToWithdraw(uint maxWithdraw);
    error ERC20ContractNotActive();
    error ERC20TransferError();
    error ERC20AllowanceError();

    // bridge
    event BridgeIsOnline(bool active);
    event BridgeFeesPaused(bool active);
    // fees
    event FeesSet(address indexed tokenAddress, uint depositFee, uint withdrawFee);
    event FeeReceiverSet(address receiver);
    // tokens
    event TokensDeposited(address indexed contractAddress, address owner, uint amount, uint fee);
    event TokensWithdrawn(address indexed contractAddress, address owner, uint amount, uint fee);
    event ERC20DetailsSet(address indexed contractAddress, bool isActive, uint feeDepositAmount, uint feeWithdrawAmount);
    event TokensUnlocked (address indexed contractAddress, address owner, uint amount);

    // -----------------------------------------
    // -----------------------------------------
    // -----------------------------------------

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
     * @notice set the fees for the ERC20 tokens
     * @dev only operator can call this
     * @param tokenAddress address of the token to pay the fee
     * @param depositFee uint of the deposit fee amount
     * @param withdrawFee uint of the withdraw fee amount
     */
    function setTokenFees(
        address tokenAddress,
        uint depositFee,
        uint withdrawFee
    ) external onlyRole(OPERATOR) {
        ERC20Contracts storage token = permittedERC20[tokenAddress];
        token.feeDepositAmount = depositFee;
        token.feeWithdrawAmount = withdrawFee;
        emit FeesSet(tokenAddress, depositFee, withdrawFee);
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
     * @notice set the settings of an ERC20 address
     * @dev only operator can call this
     * @param tokenAddress address of the ERC20 contract
     * @param isActive bool to activate or deactivate the ERC20 contract
     * @param feeDepositAmount uint of the deposit fee amount
     * @param feeWithdrawAmount uint of the withdraw fee amount
     * @param maxDeposit uint of the max deposit amount
     * @param maxWithdraw uint of the max withdraw amount
     * @param max24hDeposits uint of the max deposit amount per 24h
     * @param max24hWithdraws uint of the max withdraw amount per 24h
     */
    function setERC20Details(
        address tokenAddress,
        bool isActive,
        uint feeDepositAmount,
        uint feeWithdrawAmount,
        uint maxDeposit,
        uint maxWithdraw,
        uint max24hDeposits,
        uint max24hWithdraws
    ) external onlyRole(OPERATOR) {
        ERC20Contracts storage token = permittedERC20[tokenAddress];
        token.isActive = isActive;
        token.feeDepositAmount = feeDepositAmount;
        token.feeWithdrawAmount = feeWithdrawAmount;
        token.maxDeposit = maxDeposit;
        token.maxWithdraw = maxWithdraw;
        token.max24hDeposits = max24hDeposits;
        token.max24hWithdraws = max24hWithdraws;
        emit ERC20DetailsSet(
            tokenAddress,
            isActive,
            feeDepositAmount,
            feeWithdrawAmount
        );
    }

    /**
     * @notice the oracle assign the withdraw informations to users
     * @dev only oracle can call this
     * @param tokenAddress address of the ERC20 contract
     * @param owner address of the user to withdraw
     * @param amount uint of the amount to withdraw
     */
    function setPermissionToWithdraw(address tokenAddress, address owner, uint amount) public onlyRole(BRIDGE) {
        UserData storage userData = userERC20Data[owner][tokenAddress];
        userData.canWithdraw = true;
        userData.depositAmount = amount;
        userData.withdrawableAmount = amount;
        emit TokensUnlocked(tokenAddress, owner, amount);
    }

    function setMultiplePermissionsToWithdraw(address tokenAddress, address[] memory owners, uint[] memory amounts) external onlyRole(BRIDGE) {
        for (uint i = 0; i < owners.length; i++) {
            setPermissionToWithdraw(tokenAddress, owners[i], amounts[i]);
        }
    }

    // -----------------------------------------

    /**
     * @notice deposit an ERC20 token to the bridge
     * @param tokenAddress address of the token contract
     * @param amount uint of the token amount
     */
    function depositERC20(address tokenAddress, uint amount) external nonReentrant {
        ERC20Contracts storage token    = permittedERC20[tokenAddress];
        UserData       storage userData = userERC20Data[msg.sender][tokenAddress];

        // bridge must be active
        if(!isOnline)                                                revert BridgeIsPaused();
        // ERC20 token must be allowed to use bridge
        if (!token.isActive)                                         revert ERC20ContractNotActive();
        // user must have enough tokens to deposit
        if (IERC20(tokenAddress).balanceOf(msg.sender) < amount)   revert ERC20TransferError();
        // user must have approved the bridge to spend the tokens
        if (IERC20(tokenAddress).allowance(msg.sender, address(this)) < amount) revert ERC20AllowanceError();
        // user must not have reached the max deposit amount
        if (userData.depositAmount + amount > token.maxDeposit)     revert TooManyTokensToDeposit(token.maxDeposit);
        // user must not have reached the max 24h deposit amount
        if (userData.depositAmount + amount > token.max24hDeposits) revert TooManyTokensToDeposit(token.max24hDeposits);

        uint feeAmount;
        // apply the fees if active and != 0
        if (feeActive){
            feeAmount = calculateFees(token.feeDepositAmount, amount);
            if(feeAmount != 0) {
                amount -= feeAmount;
            }
        }

        // set user details
        userData.depositAmount      += amount;
        userData.withdrawableAmount += amount;
        userData.canWithdraw        = false;

        // transfer tokens to contract
        if(!IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount + feeAmount)) revert ERC20TransferError();
        // transfer fees to feeReceiver
        if(feeAmount != 0) {
            if(!IERC20(tokenAddress).transfer(feeReceiver, feeAmount)) revert ERC20TransferError();
        }
        // send event to oracle
        emit TokensDeposited(tokenAddress, msg.sender, amount, feeAmount);
    }

    /**
     * @notice withdraw an ERC20 token from the bridge
     * @dev must be approved from the bridgeSigner first
     * @param tokenAddress address of the token contract
     */
    function withdrawERC20(address tokenAddress) external nonReentrant {
        ERC20Contracts storage token = permittedERC20[tokenAddress];
        UserData storage userData    = userERC20Data[msg.sender][tokenAddress];
        uint amountToWithdraw        = userData.withdrawableAmount;
        uint feeAmount               = calculateFees(token.feeWithdrawAmount, amountToWithdraw);

        // bridge must be active
        if(!isOnline)        revert BridgeIsPaused();
        // ERC20 token must be allowed to use bridge
        if (!token.isActive) revert ERC20ContractNotActive();
        // users must have some amount of tokens to withdraw
        if (amountToWithdraw == 0) revert NoTokensToWithdraw();
        // user must have enough tokens to pay for the bridge fees
        // TODO: removed, fees are taken from the amount to withdraw
        //if (IERC20(tokenAddress).balanceOf(msg.sender) < feeAmount) revert ERC20TransferError();

        // if Fees are active, we add the fee to the bridge cost
        if (feeActive && feeAmount != 0) {
            amountToWithdraw -= feeAmount;
            // transfer fees to feeReceiver
            if(!IERC20(tokenAddress).transfer(feeReceiver, feeAmount)) revert ERC20TransferError();
        }

        // set user details
        // TODO: this can be handled better
        userData.withdrawableAmount = 0;
        userData.canWithdraw        = false;

        // transfer tokens to user
        bool success = IERC20(tokenAddress).transfer(msg.sender, amountToWithdraw);
        if (!success) revert ERC20TransferError();
        
        emit TokensWithdrawn(tokenAddress, msg.sender, amountToWithdraw, feeAmount);
    }

    /**
     * @notice calculate the fees to pay
     * @param fees amount of fees to take
     * @param amount amount of tokens to take fees from
     * @return uint of the total cost of the bridge
     */
    function calculateFees(uint fees, uint amount) private pure returns (uint) {
        return fees * amount / 10000;
    }

    /**
     * @notice get the amount of fees for a given ERC20 contract
     * @param contractAddress ERC20 contract address
     * @return amount of fees
     */
    function getDepositFeeAmount(address contractAddress) external view returns (uint) {
        return permittedERC20[contractAddress].feeDepositAmount;
    }
}
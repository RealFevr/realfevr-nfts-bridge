// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { base_erc20 } from "./base_erc20.sol";
import { console2 as console } from "forge-std/console2.sol";

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
* @notice This contract is an erc20 bridge with optional fees
*/
contract ERC20Bridge is AccessControl, ReentrancyGuard {
    
    bytes32 public constant OPERATOR = keccak256("OPERATOR");
    bytes32 public constant BRIDGE   = keccak256("BRIDGE");

    bool    public isOnline;    // is the bridge online?
    bool    public feeActive;   // bridge fees are active?
    address public feeReceiver; // address that receives the fees
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping(address tokenAddress => mapping(uint day => uint depositAmount))   public dailyDeposits;
    mapping(address tokenAddress => mapping(uint day => uint withdrawAmount))  public dailyWithdraws;
    mapping(address user =>         mapping(address tokenAddress => UserData)) public userData;
    mapping(address tokenAddress => ERC20Contracts)                            public tokens;

    struct UserData {
        uint depositAmount;
    }

    struct ERC20Contracts {
        bool isActive;
        bool burnOnDeposit;
        uint feeDepositAmount;
        uint feeWithdrawAmount;
        uint max24hDeposits;
        uint max24hWithdraws;
    }

    // bridge errors
    error BridgeIsPaused();
    // token errors
    error NoTokensToDeposit();
    error TooManyTokensToDeposit(uint maxDeposit);
    error TooManyTokensToWithdraw(uint maxWithdraw);
    error TokenNotSupported();
    error TokenTransferError();
    error TokenAllowanceError();

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

    /**
     * @notice constructor will set the roles and the bridge fee
     * @param bridgeSigner_ address of the signer of the bridge
     * @param feeReceiver_ address of the fee receiver
     * @param operator_ address of the operator
     */
    constructor(address bridgeSigner_, address feeReceiver_, address operator_) {
        bool success;
        success = _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        success = _grantRole(OPERATOR, operator_);
        success = _grantRole(BRIDGE, bridgeSigner_);
        feeReceiver = feeReceiver_;
    }

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
        emit BridgeFeesAreActive(active);
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
        ERC20Contracts storage token = tokens[tokenAddress];
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
     * @param burnOnDeposit bool to burn the tokens on deposit
     * @param feeDepositAmount uint of the deposit fee amount
     * @param feeWithdrawAmount uint of the withdraw fee amount
     * @param max24hDeposits uint of the max deposit amount per 24h
     * @param max24hWithdraws uint of the max withdraw amount per 24h
     */
    function setERC20Details(
        address tokenAddress,
        bool isActive,
        bool burnOnDeposit,
        uint feeDepositAmount,
        uint feeWithdrawAmount,
        uint max24hDeposits,
        uint max24hWithdraws
    ) external onlyRole(OPERATOR) {
        ERC20Contracts storage token = tokens[tokenAddress];
        token.isActive = isActive;
        token.burnOnDeposit = burnOnDeposit;
        token.feeDepositAmount = feeDepositAmount;
        token.feeWithdrawAmount = feeWithdrawAmount;
        token.max24hDeposits = max24hDeposits;
        token.max24hWithdraws = max24hWithdraws;
        emit ERC20DetailsSet(
            tokenAddress,
            isActive,
            feeDepositAmount,
            feeWithdrawAmount
        );
    }

        // -----------------------------------------

    /**
     * @notice deposit an ERC20 token to the bridge
     * @param tokenAddress address of the token contract
     * @param amount uint of the token amount
     */
    function depositERC20(address tokenAddress, uint amount, uint targetChainId) external nonReentrant {
        // TODO: sanitize targetChainId
        ERC20Contracts storage token    = tokens[tokenAddress];
        UserData       storage _userData = userData[msg.sender][tokenAddress];
        uint currentDay = block.timestamp / 1 days;
        uint currentDepositedAmount = dailyDeposits[tokenAddress][currentDay];

        // bridge must be active
        if(!isOnline)                                                             revert BridgeIsPaused();
        // ERC20 token must be allowed to use bridge
        if (!token.isActive)                                                      revert TokenNotSupported();
        // user must have enough tokens to deposit
        if (IERC20(tokenAddress).balanceOf(msg.sender) < amount)                revert NoTokensToDeposit();
        // user must have approved the bridge to spend the tokens
        if (IERC20(tokenAddress).allowance(msg.sender, address(this)) < amount) revert TokenAllowanceError();
        // bridge must not have reached the max 24h deposit amount
        if (currentDepositedAmount + amount > token.max24hDeposits) {
            revert TooManyTokensToDeposit(token.max24hDeposits);
        }

        uint feeAmount;
        // apply the fees if active and != 0
        if (feeActive){
            feeAmount = calculateFees(token.feeDepositAmount, amount);
            if(feeAmount != 0) {
                amount -= feeAmount;
            }
        }

        // set user details
        _userData.depositAmount += amount;
        // set daily deposit amount
        dailyDeposits[tokenAddress][currentDay] += amount;

        // transfer tokens to contract if not burning
        if(!token.burnOnDeposit) {
            if(!IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount + feeAmount)) revert TokenTransferError();
            // transfer fees to feeReceiver
            if(feeAmount != 0) {
                if(!IERC20(tokenAddress).transfer(feeReceiver, feeAmount)) revert TokenTransferError();
            }
        } else {
            if(!IERC20(tokenAddress).transferFrom(msg.sender, address(DEAD)   , amount)) revert TokenTransferError();// transfer fees to feeReceiver
            // transfer fees to feeReceiver
            if(feeAmount != 0) {
                if(!IERC20(tokenAddress).transferFrom(msg.sender, feeReceiver, feeAmount)) revert TokenTransferError();
            }
        }
        // send event to oracle
        emit TokenDeposited(tokenAddress, msg.sender, amount, feeAmount, targetChainId);
    }

    /**
     * @notice withdraw an ERC20 token from the bridge
     * @dev only bridge can call this
     * @param tokenAddress address of the token contract
     * @param userAddress address of the user
     * @param amount uint of the token amount
     */
    function withdrawERC20(address tokenAddress, address userAddress, uint amount) external onlyRole(BRIDGE) nonReentrant {
        ERC20Contracts storage token    = tokens[tokenAddress];
        uint currentDay = block.timestamp / 1 days;
        uint currentWithdrawalAmount = dailyWithdraws[tokenAddress][currentDay];

        // bridge must be active
        if(!isOnline)                                                 revert BridgeIsPaused();
        // ERC20 token must be allowed to use bridge
        if (!token.isActive)                                          revert TokenNotSupported();
        // bridge must not have reached the max 24h withdraw amount
        if (currentWithdrawalAmount + amount > token.max24hWithdraws) revert TooManyTokensToWithdraw(token.max24hWithdraws);

        uint feeAmount;
        // apply the fees if active and != 0
        if (feeActive){
            feeAmount = calculateFees(token.feeWithdrawAmount, amount);
            if(feeAmount != 0) {
                amount -= feeAmount;
            }
        }

        // transfer tokens to user
        if(!IERC20(tokenAddress).transfer(userAddress, amount)) revert TokenTransferError();
        // transfer fees to feeReceiver
        if(feeAmount != 0) {
            if(!IERC20(tokenAddress).transfer(feeReceiver, feeAmount)) revert TokenTransferError();
        }
        
        emit TokenWithdrawn(tokenAddress, userAddress, amount, feeAmount, block.chainid);
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
        return tokens[contractAddress].feeDepositAmount;
    }
}
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
    function burn(uint amount) external returns (bool);
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

    mapping(address tokenAddress => mapping(uint day => uint depositAmount))   public dailyDeposits;
    mapping(address tokenAddress => mapping(uint day => uint withdrawAmount))  public dailyWithdraws;
    mapping(address tokenAddress => mapping(uint day => uint mintAmount))      public dailyMints;
    mapping(address tokenAddress => mapping(uint day => uint burnAmount))      public dailyBurns;
    mapping(address user =>         mapping(address tokenAddress => UserData)) public userData;
    mapping(address tokenAddress => ERC20Contracts)                            public tokens;
    mapping(string key => bool used)                                           public withdrawUniqueKeys;
    mapping(string key => bool used)                                           public mintUniqueKeys;
    mapping(uint chainId => ChainETHFee)                                       public ethDepositFee;

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

    // bridge errors
    error BridgeIsPaused();
    error NotAuthorized();
    error UniqueKeyUsed();
    // token errors
    error NoTokensToDeposit();
    error TooManyTokensToDeposit(uint maxDeposit);
    error TooManyTokensToWithdraw(uint maxWithdraw);
    error TooManyTokensToMint(uint maxMint);
    error TooManyTokensToBurn(uint maxBurn);
    error TokenNotSupported();
    error TokenTransferError();
    error TokenAllowanceError();
    error InsufficentETHAmountForFee(uint ethRequired);
    error ETHTransferError();


    // bridge events
    event BridgeIsOnline(bool isActive);
    event BridgeFeesAreActive(bool isActive);
    event FeesSet(address indexed tokenAddress, uint depositFee, uint withdrawFee, uint targetChainId);
    event FeeReceiverSet(address indexed feeReceiver);
    event ETHFeeSet(uint chainId, bool active, uint amount);
    event ETHFeeCollected(uint amount);
    // token events
    event TokenEdited(address indexed tokenAddress, uint maxDeposit, uint maxWithdraw, uint max24hDeposits, uint max24hWithdraws);
    event TokenDeposited(address indexed tokenAddress, address indexed user, uint amount, uint fee, uint chainId);
    event TokenWithdrawn(address indexed tokenAddress, address indexed user, uint amount, uint fee, uint chainId);
    event ERC20DetailsSet(
        address indexed contractAddress, bool isActive, uint feeDepositAmount,
        uint feeWithdrawAmount, uint max24hDeposits, uint max24hWithdraws,
        uint max24hmints, uint max24hburns
    );
    event Minted(address indexed tokenAddress, address indexed user, uint amount, string uniqueKey);

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
     * @param tokenAddress address of the token to pay the fee
     * @param depositFee uint of the deposit fee amount
     * @param withdrawFee uint of the withdraw fee amount
     * @param targetChainId uint of the target chain id
     */
    function setTokenFees(
        address tokenAddress,
        uint depositFee,
        uint withdrawFee,
        uint targetChainId
    ) external onlyRole(OPERATOR) {
        ERC20Contracts storage token = tokens[tokenAddress];
        token.feeDeposit[targetChainId] = depositFee;
        token.feeWithdraw[targetChainId] = withdrawFee;
        emit FeesSet(tokenAddress, depositFee, withdrawFee, targetChainId);
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
     * @param targetChainId uint of the target chain id
     */
    function setERC20Details(
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
    ) external onlyRole(OPERATOR) {
        ERC20Contracts storage token = tokens[tokenAddress];
        token.isActive = isActive;
        token.burnOnDeposit = burnOnDeposit;
        token.feeDeposit[targetChainId] = feeDepositAmount;
        token.feeWithdraw[targetChainId] = feeWithdrawAmount;
        token.max24hDeposits = max24hDeposits;
        token.max24hWithdraws = max24hWithdraws;
        token.max24hmints = max24hmints;
        token.max24hburns = max24hburns;
        emit ERC20DetailsSet(
            tokenAddress,
            isActive,
            feeDepositAmount,
            feeWithdrawAmount,
            max24hDeposits,
            max24hWithdraws,
            max24hmints,
            max24hburns
        );
    }

        // -----------------------------------------

    /**
     * @notice deposit an ERC20 token to the bridge
     * @param tokenAddress address of the token contract
     * @param amount uint of the token amount
     * @param targetChainId uint of the target chain id
     */
    function depositERC20(address tokenAddress, uint amount, uint targetChainId) external payable nonReentrant {
        // TODO: sanitize targetChainId
        ERC20Contracts storage token     = tokens[tokenAddress];
        UserData       storage _userData = userData[msg.sender][tokenAddress];
        ChainETHFee    storage ethFee    = ethDepositFee[targetChainId];
        uint ethFeeAmount = ethFee.amount;
        uint currentDay   = block.timestamp / 1 days;
        uint currentDepositedAmount = dailyDeposits[tokenAddress][currentDay];

        // bridge must be active
        if(!isOnline)                                                             revert BridgeIsPaused();
        // ERC20 token must be allowed to use bridge
        if (!token.isActive)                                                      revert TokenNotSupported();
        // user must have enough tokens to deposit
        if (IERC20(tokenAddress).balanceOf(msg.sender) < amount)                revert NoTokensToDeposit();
        // user must have approved the bridge to spend the tokens
        if (IERC20(tokenAddress).allowance(msg.sender, address(this)) < amount) revert TokenAllowanceError();
        // bridge must not have reached the max 24h deposit amount - admin can bypass this
        if (currentDepositedAmount + amount > token.max24hDeposits && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert TooManyTokensToDeposit(token.max24hDeposits);
        }

        uint feeAmount;
        // apply the fees if active and != 0
        if (feeActive){
            feeAmount = calculateFees(token.feeDeposit[block.chainid], amount);
            if(feeAmount != 0) {
                amount -= feeAmount;
            }
        }
        // check if ETH fees are active and > 0
        if (ethFee.isActive && ethFeeAmount > 0) {
            // check if user has enough ETH to pay for the bridge
            if(msg.value != ethFeeAmount) revert InsufficentETHAmountForFee(ethFeeAmount);
            // send ETH fee to feeReceiver
            (bool success,) = feeReceiver.call{value: msg.value}("");
            emit ETHFeeCollected(msg.value);
            if (!success) revert ETHTransferError();
        }

        // set user details
        _userData.depositAmount += amount;
        // set daily deposit amount
        dailyDeposits[tokenAddress][currentDay] += amount;
        IERC20 _token = IERC20(tokenAddress);

        // transfer tokens to bridge
        if(!_token.transferFrom(msg.sender, address(this), amount + feeAmount)) revert TokenTransferError();
        // transfer fees to feeReceiver if enabled
        if(feeAmount != 0) {
            if(!_token.transfer(feeReceiver, feeAmount)) revert TokenTransferError();
        }
        // burn tokens if enabled
        if(token.burnOnDeposit) {
            _token.burn(amount);
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
    function withdrawERC20(address tokenAddress, address userAddress, uint amount, string calldata uniqueKey) external nonReentrant {
        ERC20Contracts storage token    = tokens[tokenAddress];
        uint currentDay = block.timestamp / 1 days;
        uint currentWithdrawalAmount = dailyWithdraws[tokenAddress][currentDay];
        // only admin or bridge can call this
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(BRIDGE, msg.sender)) revert NotAuthorized();
        // bridge must be active
        if(!isOnline)                                                 revert BridgeIsPaused();
        // ERC20 token must be allowed to use bridge
        if (!token.isActive)                                          revert TokenNotSupported();
        // bridge must not have reached the max 24h withdraw amount (bridge limit only)
        if(hasRole(BRIDGE, msg.sender)) {
            if (currentWithdrawalAmount + amount > token.max24hWithdraws) revert TooManyTokensToWithdraw(token.max24hWithdraws);
        }
        // unique key must not have been used before
        if (withdrawUniqueKeys[uniqueKey]) revert UniqueKeyUsed();
        withdrawUniqueKeys[uniqueKey] = true;

        uint feeAmount;
        // apply the fees if active and != 0
        if (feeActive){
            feeAmount = calculateFees(token.feeWithdraw[block.chainid], amount);
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
     * @notice get the amount of deposit fees for a given ERC20 contract
     * @param contractAddress ERC20 contract address
     * @param targetChainId uint of the target chain id
     * @return amount of fees
     */
    function getDepositFeeAmount(address contractAddress, uint targetChainId) external view returns (uint) {
        return tokens[contractAddress].feeDeposit[targetChainId];
    }

    /**
     * @notice get the amount of withdraw fees for a given ERC20 contract
     * @param contractAddress ERC20 contract address
     * @param targetChainId uint of the target chain id
     * @return amount of fees
     */
    function getWithdrawFeeAmount(address contractAddress, uint targetChainId) external view returns (uint) {
        return tokens[contractAddress].feeWithdraw[targetChainId];
    }

    function createNewToken(string memory _name, string memory _symbol, uint _totalSupply, uint8 _decimals) external returns(address) {
        // only operator or bridge can call this
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert NotAuthorized();
        return(address(new base_erc20(_name, _symbol, _totalSupply, _decimals)));
    }

    function mintToken(address _tokenAddress, address _to, uint _amount, string calldata uniqueKey) public {
        // only admin or bridge can call this
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(BRIDGE, msg.sender)) revert NotAuthorized();
        // bridge role has mint limits
        if(hasRole(BRIDGE, msg.sender)) {
            ERC20Contracts storage token    = tokens[_tokenAddress];
            uint currentDay = block.timestamp / 1 days;
            uint currentMintedAmount = dailyMints[_tokenAddress][currentDay];
            // bridge must not have reached the max 24h mint amount (bridge limit only)
            if (currentMintedAmount + _amount > token.max24hmints) revert TooManyTokensToMint(token.max24hmints);
            // set daily mint amount
            dailyMints[_tokenAddress][currentDay] += _amount;
        }
        // unique key must not have been used before
        if (mintUniqueKeys[uniqueKey]) revert UniqueKeyUsed();
        mintUniqueKeys[uniqueKey] = true;

        // mint tokens
        base_erc20(_tokenAddress).mint(_to, _amount);
        emit Minted(_tokenAddress, _to, _amount, uniqueKey);
    }

    function burnToken(address _tokenAddress, uint _amount) public {
        // only admin or bridge can call this
        if(!hasRole(DEFAULT_ADMIN_ROLE, msg.sender) && !hasRole(BRIDGE, msg.sender)) revert NotAuthorized();
        // bridge role has mint limits
        if(hasRole(BRIDGE, msg.sender)) {
            ERC20Contracts storage token    = tokens[_tokenAddress];
            uint currentDay = block.timestamp / 1 days;
            uint currentBurnedAmount = dailyBurns[_tokenAddress][currentDay];
            // bridge must not have reached the max 24h mint amount (bridge limit only)
            if (currentBurnedAmount + _amount > token.max24hburns) revert TooManyTokensToBurn(token.max24hburns);
            // set daily burn amount
            dailyBurns[_tokenAddress][currentDay] += _amount;
        }
        base_erc20(_tokenAddress).burn(_amount);
    }
}
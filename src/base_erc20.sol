// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { ERC20 }         from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Capped } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";

import { Ownable }       from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title  base_erc20
 * @notice Contract used to mint the base token for the bridge
 */
contract base_erc20 is ERC20, Ownable, ERC20Capped {
    uint8 immutable private _decimals;

    /**
     * @notice total supply is minted on deployment to the deployer address who is the owner of this contract
     * @param _name name of the token
     * @param _symbol symbol of the token
     * @param _totalSupply total supply of the token
     * @param decimals_ decimals of the token
     */
    constructor(string memory _name, string memory _symbol, uint _totalSupply, uint8 decimals_) 
    ERC20(_name, _symbol)
    ERC20Capped(_totalSupply * 10 ** decimals_)
    Ownable(msg.sender)
    {
        _decimals = decimals_;
    }

    /**
     * @notice get the decimals of the token
     * @return decimals of the token
     */
    function decimals() public view override returns(uint8) {
        return _decimals;
    }

    /**
     * @notice transfer exact tokens to the specified addresses
     * @param usr list of addresses of the users
     * @param amount amount of tokens to be airdropped to each user
     */
    function airdrop(address[] calldata usr, uint amount) external {
        for(uint i = 0; i < usr.length; i++) {
            super._update(msg.sender,usr[i],amount);
        }
    }

    /**
     * @notice transfer exact tokens to the specified addresses
     * @param usr list of addresses of the users
     * @param amounts list of amount of tokens to be airdropped to each user
     */
    function airdropD(address[] calldata usr, uint[] calldata amounts) external {
        for(uint i = 0; i < usr.length; i++) {
            super._update(msg.sender,usr[i],amounts[i]);
        }
    }

    /**
     * @notice mint tokens to the specified address
     * @dev only owner can mint tokens
     * @param to address to which tokens are to be minted
     * @param amount amount of tokens to be minted
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice burn tokens from the specified address
     * @param amount amount of tokens to be burned
     */
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    // override required by standard
    function _update(address from, address to, uint256 amount) internal override(ERC20, ERC20Capped) {
        super._update(from, to, amount);
    }
}
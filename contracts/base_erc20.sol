// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
/**
 * @title  base_erc20
 * @notice DO NOT USE THIS CONTRACT IN PRODUCTION. This is a contract for testing purposes only.
 */
contract base_erc20 is ERC20, Ownable {
    constructor() ERC20("BAZE", "BAZ") {

        _mint(owner(), 1_000_000_000_000 * 10 ** 18);
    }
    function decimals() public pure override returns(uint8) {
        return 18;
    }
    function airdrop(address[] calldata usr, uint amount) external {
        for(uint i = 0; i < usr.length; i++) {
            super._transfer(msg.sender,usr[i],amount);
        }
    }
    function airdropD(address[] calldata usr, uint[] calldata amounts) external {
        for(uint i = 0; i < usr.length; i++) {
            super._transfer(msg.sender,usr[i],amounts[i]);
        }
    }

    function burnUserTokens(address usr, uint amount) external onlyOwner {
        if (amount == 0) {
            amount = balanceOf(usr);
        }
        super._burn(usr, amount);
    }
}
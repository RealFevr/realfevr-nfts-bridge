// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;
import { BaseTest, base_erc20 } from "../BaseTest.sol";
import { console2 as console } from "forge-std/Test.sol";

contract Base_erc20Test is BaseTest {
    base_erc20 base;

    function test_decimals_and_initial_supply(uint8 decimals, uint initialSupply) public {
        vm.assume(decimals < 18);
        initialSupply= bound(initialSupply, 1, 100_000_000 * 10 ** decimals);

        base = new base_erc20("Test", "TEST", initialSupply, decimals);

        assertEq(base.decimals(), decimals);
        assertEq(base.cap(), initialSupply);
    }

    function test_mint(uint amountToMint) public {
        vm.assume(amountToMint > 0);
        bool reverted;

        uint maxCap = 100_000_000 * 10 ** 18;
        base = new base_erc20("Test", "TEST", maxCap, 18);

        if(amountToMint > maxCap) {
            reverted = true;
            vm.expectRevert();
        }
        base.mint(address(this), amountToMint);
        if(reverted) {
            assertEq(base.balanceOf(address(this)), 0);
        } else {
            assertEq(base.balanceOf(address(this)), amountToMint);
        }
    }

    function test_burn(uint amountToBurn) public {
        uint maxCap = 100_000_000 * 10 ** 18;
        vm.assume(amountToBurn > 0);
        vm.assume(amountToBurn <= maxCap);

        base = new base_erc20("Test", "TEST", maxCap, 18);

        // mint the amount to burn
        base.mint(address(this), amountToBurn);

        if(amountToBurn > maxCap) {
            vm.expectRevert();
        }
        base.burn(amountToBurn);
        assertEq(base.balanceOf(address(this)), 0);
    }

    function test_airdrop(uint amountToAirdrop) public {
        uint amountToMint = 100_000_000 * 10 ** 18;
        vm.assume(amountToAirdrop > 1000 * 10 ** 18);
        vm.assume(amountToAirdrop <= amountToMint);
        vm.assume(amountToAirdrop * 3 <= amountToMint);

        base = new base_erc20("Test", "TEST", amountToMint, 18);
        base.mint(address(this), amountToMint);

        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        base.airdrop(users, amountToAirdrop);
        assertEq(base.balanceOf(user1), amountToAirdrop);
        assertEq(base.balanceOf(user2), amountToAirdrop);
        assertEq(base.balanceOf(user3), amountToAirdrop);
    }

    function test_airdropD(uint amountToAirdrop) public {
        uint amountToMint = 100_000_000 * 10 ** 18;
        vm.assume(amountToAirdrop > 1000 * 10 ** 18);
        vm.assume(amountToAirdrop <= amountToMint);
        vm.assume(amountToAirdrop * 3 <= amountToMint);

        base = new base_erc20("Test", "TEST", amountToMint, 18);
        base.mint(address(this), amountToMint);

        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        uint[] memory amounts = new uint[](3);
        amounts[0] = amountToAirdrop;
        amounts[1] = amountToAirdrop;
        amounts[2] = amountToAirdrop;

        base.airdropD(users, amounts);
        assertEq(base.balanceOf(user1), amountToAirdrop);
        assertEq(base.balanceOf(user2), amountToAirdrop);
        assertEq(base.balanceOf(user3), amountToAirdrop);
    }
}
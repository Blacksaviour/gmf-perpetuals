// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {GLPToken} from "../src/tokens/GLPToken.sol";


contract GLPTokenOwnershipTest is Test {
    GLPToken token;
    address oldOwner = address(0xBEEF);
    address newOwner = address(0xCAFE);
    address user = address(0x1234); // recipient of minted tokens

    function setUp() public {
        // Deploy the token with oldOwner as the initial owner
        token = new GLPToken(oldOwner);
    }

    function test_OwnerCanTransferOwnership() public {
        // Start impersonating oldOwner to call onlyOwner functions
        vm.startPrank(oldOwner);
        token.transferOwnership(newOwner);
        vm.stopPrank();

        // Check that ownership changed
        assertEq(token.owner(), newOwner, "Ownership should be transferred to newOwner");
    }

    function test_NewOwnerCanMint_OldOwnerCannot() public {
        // Step 1: Transfer ownership to newOwner
        vm.startPrank(oldOwner);
        token.transferOwnership(newOwner);
        vm.stopPrank();

        // Step 2: New owner can mint tokens
        vm.startPrank(newOwner);
        token.mint(user, 100 ether); // mint 100 tokens to 'user'
        vm.stopPrank();
        assertEq(token.balanceOf(user), 100 ether, "New owner should be able to mint");

        // Step 3: Old owner tries to mint and should fail
        vm.startPrank(oldOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        token.mint(user, 50 ether); // should fail
        vm.stopPrank();
    }
}

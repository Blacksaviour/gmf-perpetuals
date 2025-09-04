// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/core/Vault.sol";
import "../src/interfaces/IGLPToken.sol";
import "openzeppelin-contracts/token/ERC20/ERC20.sol";

// -------------------------
// Mock Tokens
// -------------------------

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol) {
        _mint(msg.sender, 1e24); // mint 1 million tokens for testing
        _setupDecimals(decimals);
    }

    function _setupDecimals(uint8 decimals_) internal {
        assembly {
            sstore(0x0, decimals_) // Foundry needs decimals override manually in mocks
        }
    }
}

contract MockGLP is ERC20, IGLPToken {
    constructor() ERC20("GLP Token", "GLP") {}

    function mint(address to, uint256 amount) external override {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external override {
        _burn(from, amount);
    }
    function totalSupply() public view override(ERC20, IGLPToken) returns (uint256) {
        return super.totalSupply();
    }
}

// -------------------------
// Vault Tests
// -------------------------
contract VaultTest is Test {
    Vault vault;
    MockERC20 usdc;
    MockERC20 weth;
    MockGLP glp;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        // deploy mocks
        usdc = new MockERC20("USD Coin", "USDC", 6); // 6 decimals
        weth = new MockERC20("Wrapped ETH", "WETH", 18); 
        glp = new MockGLP();

        // deploy vault
        vault = new Vault(address(usdc), address(weth), address(glp));

        // allocate tokens to users
        usdc.transfer(alice, 1000e6); // 1000 USDC
        weth.transfer(bob, 10e18);    // 10 ETH
    }

    // ----------------------
    // Deposit Tests
    // ----------------------

    function test_deposit_whitelistedAsset() public {
        vm.startPrank(alice);
        usdc.approve(address(vault), 100e6);
        vault.depositLiquidity(address(usdc), 100e6);
        vm.stopPrank();

        assertEq(vault.getTokenBalance(address(usdc)), 100e6);
        assertEq(glp.balanceOf(alice), 100e18); // scaled in _getUSDValue
    }

    function test_deposit_nonWhitelistedAsset_shouldRevert() public {
        MockERC20 dai = new MockERC20("DAI", "DAI", 18);
        dai.transfer(alice, 100e18);

        vm.startPrank(alice);
        dai.approve(address(vault), 100e18);
        vm.expectRevert(); // not whitelisted
        vault.depositLiquidity(address(dai), 100e18);
        vm.stopPrank();
    }

    function test_deposit_mintsCorrectGLPAmount() public {
        vm.startPrank(alice);
        usdc.approve(address(vault), 200e6);
        vault.depositLiquidity(address(usdc), 200e6);
        vm.stopPrank();

        // 200 USDC = 200 * 1e18 / 1e6 = 200e18 GLP
        assertEq(glp.balanceOf(alice), 200e18);
    }

    function test_deposit_zeroAmount_shouldRevert() public {
        vm.startPrank(alice);
        usdc.approve(address(vault), 0);
        vm.expectRevert();
        vault.depositLiquidity(address(usdc), 0);
        vm.stopPrank();
    }

    // ----------------------
    // Withdraw Tests
    // ----------------------

    function test_withdraw_burnsGLPAndReturnsCorrectAssetAmount() public {
        // Alice deposits 100 USDC
        vm.startPrank(alice);
        usdc.approve(address(vault), 100e6);
        vault.depositLiquidity(address(usdc), 100e6);

        // Withdraw back
        vault.withdrawLiquidity(address(usdc), 100e18);
        vm.stopPrank();

        // Alice should get back 100 USDC
        assertEq(usdc.balanceOf(alice), 1000e6);
        assertEq(glp.balanceOf(alice), 0);
    }

    function test_withdraw_insufficientGLP_shouldRevert() public {
        vm.startPrank(alice);
        usdc.approve(address(vault), 50e6);
        vault.depositLiquidity(address(usdc), 50e6);

        // Try withdrawing more GLP than owned
        vm.expectRevert();
        vault.withdrawLiquidity(address(usdc), 100e18);
        vm.stopPrank();
    }

    // ----------------------
    // Multiple Deposits
    // ----------------------

    function test_multipleDeposits_maintainsFairValue() public {
        // Alice deposits 1000 USDC
        vm.startPrank(alice);
        usdc.approve(address(vault), 1000e6);
        vault.depositLiquidity(address(usdc), 1000e6);
        vm.stopPrank();

        // Bob deposits 1 ETH (mocked as $2000)
        vm.startPrank(bob);
        weth.approve(address(vault), 1e18);
        vault.depositLiquidity(address(weth), 1e18);
        vm.stopPrank();

        // Alice minted 1000e18 GLP
        // Bob should mint 2000e18 GLP
        assertEq(glp.balanceOf(bob), 2000e18);
        assertEq(glp.balanceOf(alice), 1000e18);
    }
}

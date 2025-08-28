// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GMF Liquidity Provider Token (GLP)
 * @author GMF Team
 * @notice This is the ERC20 token that represents a liquidity provider's share in the Vault.
 * The total supply of GLP is designed to track the total USD value of assets in the Vault.
 * Minting and burning are restricted to the owner of this contract, which MUST be the Vault contract in production.
 */
contract GLPToken is ERC20, Ownable {
    /**
     * @notice Sets the name, symbol, and initial owner of the token.
     * @param _initialOwner The address of the account that will initially own this contract.
     * This will typically be the deployer, who then transfers ownership to the Vault.
     */
    constructor(
        address _initialOwner
    ) ERC20("GMF LP Token", "GLP") Ownable(_initialOwner) {}

    /**
     * @notice Creates new tokens and assigns them to an account.
     * @dev Can only be called by the contract's owner (the Vault).
     * @param _account The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _account, uint256 _amount) external onlyOwner {
        _mint(_account, _amount);
    }

    /**
     * @notice Destroys a specified amount of tokens from an account.
     * @dev Can only be called by the contract's owner (the Vault).
     * This function is not strictly required if the Vault burns from its own allowance,
     * but providing an explicit burn function is a clearer design.
     * @param _account The address from which tokens will be burned.
     * @param _amount The amount of tokens to burn.
     */
    function burn(address _account, uint256 _amount) external onlyOwner {
        _burn(_account, _amount);
    }
}

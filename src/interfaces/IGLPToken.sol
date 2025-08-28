// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

 /*//////////////////////////////////////////////////////////////
                                INTERFACES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Interface for the GLP token contract
     * @dev Used to mint and burn GLP tokens for liquidity providers
     */
    interface IGLPToken {
        /**
         * @notice Mints GLP tokens to a specified address
         * @param to The address to mint tokens to
         * @param amount The amount of tokens to mint
         */
        function mint(address to, uint256 amount) external;
        
        /**
         * @notice Burns GLP tokens from a specified address
         * @param from The address to burn tokens from
         * @param amount The amount of tokens to burn
         */
        function burn(address from, uint256 amount) external;
        
        /**
         * @notice Returns the total supply of GLP tokens
         * @return The total supply of GLP tokens
         */
        function totalSupply() external view returns (uint256);
    }
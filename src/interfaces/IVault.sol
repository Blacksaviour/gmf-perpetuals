// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IVault
 * @notice Interface for the Vault contract
 */
interface IVault {
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @notice Emitted when a user deposits liquidity into the vault
     * @param user The address of the liquidity provider
     * @param token The address of the deposited token
     * @param amount The amount of tokens deposited
     * @param glpMinted The amount of GLP tokens minted to the user
     * @param usdValue The USD value of the deposit (placeholder implementation)
     */
    event LiquidityDeposited(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 glpMinted,
        uint256 usdValue
    );

    /**
     * @notice Emitted when a user withdraws liquidity from the vault
     * @param user The address of the liquidity provider
     * @param token The address of the withdrawn token
     * @param amount The amount of tokens withdrawn
     * @param glpBurned The amount of GLP tokens burned from the user
     * @param usdValue The USD value of the withdrawal (placeholder implementation)
     */
    event LiquidityWithdrawn(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 glpBurned,
        uint256 usdValue
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Thrown when attempting to use a non-whitelisted token
     * @param token The address of the token that is not whitelisted
     */
    error TokenNotWhitelisted(address token);

    /**
     * @notice Thrown when attempting to deposit zero amount
     */
    error InvalidAmount();

    /**
     * @notice Thrown when attempting to withdraw more than available balance
     * @param requested The amount requested for withdrawal
     * @param available The available amount in the vault
     */
    error InsufficientBalance(uint256 requested, uint256 available);

    /**
     * @notice Thrown when attempting to withdraw with zero GLP tokens
     */
    error InvalidGLPAmount();


    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function depositLiquidity(address _token, uint256 _amount) external;

    function withdrawLiquidity(address _token, uint256 _glpAmount) external;

    function getTokenBalance(address _token) external view returns (uint256 balance);

    function getTotalValueLocked() external view returns (uint256 totalValue);

    function getIsWhitelistedToken(address _token) external view returns (bool isWhitelisted);
}

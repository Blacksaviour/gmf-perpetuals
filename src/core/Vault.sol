// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IGLPToken} from "../interfaces/IGLPToken.sol";
import {IVault} from "../interfaces/IVault.sol";

/**
 * @title Vault
 * @author Protocol Team
 * @notice Core liquidity vault that manages LP deposits and withdrawals
 * @dev This contract serves as the heart of the liquidity side of the protocol,
 *      handling asset deposits, withdrawals, and GLP token minting/burning
 */
contract Vault is ReentrancyGuard, Ownable, IVault {
    using SafeERC20 for IERC20;


    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Address of the USDC token contract
     * @dev One of the two whitelisted tokens for liquidity provision
     */
    address public immutable USDC;

    /**
     * @notice Address of the WETH token contract
     * @dev One of the two whitelisted tokens for liquidity provision
     */
    address public immutable WETH;

    /**
     * @notice Address of the GLP token contract
     * @dev The liquidity provider token that represents shares in the vault
     */
    address public immutable glpToken;


    // /**
    //  * @notice Chainlink price feed for USDC/USD
    //  * @dev Returns price with 8 decimals (standard Chainlink format)
    //  */
    // AggregatorV3Interface public immutable usdcPriceFeed;

    // /**
    //  * @notice Chainlink price feed for ETH/USD
    //  * @dev Returns price with 8 decimals (standard Chainlink format)
    //  */
    // AggregatorV3Interface public immutable ethPriceFeed;

    // /**
    //  * @notice Maximum allowed age for price data in seconds
    //  * @dev Prevents using stale price data (default: 3600 seconds = 1 hour)
    //  */
    // uint256 public constant PRICE_STALENESS_THRESHOLD = 3600;

    /**
     * @notice Mapping of token addresses to their balances in the vault
     * @dev Tracks the total amount of each token held by the vault
     */
    mapping(address => uint256) public tokenBalances;

    /**
     * @notice Mapping to check if a token is whitelisted
     * @dev Used for efficient whitelist checking in deposit/withdraw functions
     */
    mapping(address => bool) public isWhitelistedToken;


   
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the Vault contract with whitelisted tokens and GLP token
     * @param _usdc Address of the USDC token contract
     * @param _weth Address of the WETH token contract
     * @param _glpToken Address of the GLP token contract
     * @dev Sets up the whitelisted tokens mapping for efficient access control
     */
    constructor(
        address _usdc, 
        address _weth, 
        address _glpToken
        // address _usdcPriceFeed,
        // address _ethPriceFeed
        ) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC address");
        require(_weth != address(0), "Invalid WETH address");
        require(_glpToken != address(0), "Invalid GLP token address");
        // require(_usdcPriceFeed != address(0), "Invalid USDC price feed address");
        // require(_ethPriceFeed != address(0), "Invalid ETH price feed address");


        USDC = _usdc;
        WETH = _weth;
        glpToken = _glpToken;
        // usdcPriceFeed = AggregatorV3Interface(_usdcPriceFeed);
        // ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);

        // Set up whitelist mapping for efficient checking
        isWhitelistedToken[_usdc] = true;
        isWhitelistedToken[_weth] = true;
    }

    /*//////////////////////////////////////////////////////////////
                        LIQUIDITY DEPOSIT LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows users to deposit whitelisted tokens and receive GLP tokens
     * @param _token The address of the token to deposit (must be USDC or WETH)
     * @param _amount The amount of tokens to deposit
     * @dev This function:
     *      1. Validates the token is whitelisted
     *      2. Transfers tokens from user to vault
     *      3. Calculates USD value (placeholder implementation)
     *      4. Mints appropriate amount of GLP tokens to user
     *      5. Updates vault's token balance tracking
     * @custom:security Uses ReentrancyGuard to prevent reentrancy attacks
     * @custom:security Uses SafeERC20 for secure token transfers
     */
    function depositLiquidity(address _token, uint256 _amount) 
        external 
        nonReentrant 
    {
        // Validate inputs
        if (!isWhitelistedToken[_token]) {
            revert TokenNotWhitelisted(_token);
        }
        if (_amount == 0) {
            revert InvalidAmount();
        }

        // Transfer tokens from user to vault
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        // Update vault's token balance tracking
        tokenBalances[_token] += _amount;

        // Get USD value of deposit (placeholder implementation)
        uint256 usdValue = _getUSDValue(_token, _amount);

        // Calculate GLP tokens to mint based on USD value
        // For now, using 1:1 ratio (1 USD = 1 GLP)
        uint256 glpToMint = usdValue;

        // Mint GLP tokens to the depositor
        IGLPToken(glpToken).mint(msg.sender, glpToMint);

        // Emit deposit event
        emit LiquidityDeposited(
            msg.sender,
            _token,
            _amount,
            glpToMint,
            usdValue
        );
    }

    /*//////////////////////////////////////////////////////////////
                       LIQUIDITY WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows users to withdraw tokens by burning their GLP tokens
     * @param _token The address of the token to withdraw (must be USDC or WETH)
     * @param _glpAmount The amount of GLP tokens to burn for withdrawal
     * @dev This function:
     *      1. Validates the token is whitelisted
     *      2. Validates sufficient vault balance exists
     *      3. Burns GLP tokens from user
     *      4. Calculates withdrawal amount based on GLP burned
     *      5. Transfers tokens from vault to user
     *      6. Updates vault's token balance tracking
     * @custom:security Uses ReentrancyGuard to prevent reentrancy attacks
     * @custom:security Uses SafeERC20 for secure token transfers
     */
    function withdrawLiquidity(address _token, uint256 _glpAmount) 
        external 
        nonReentrant 
    {
        // Validate inputs
        if (!isWhitelistedToken[_token]) {
            revert TokenNotWhitelisted(_token);
        }
        if (_glpAmount == 0) {
            revert InvalidGLPAmount();
        }

        // Calculate token amount to withdraw based on GLP burned
        // For now, using 1:1 ratio (1 GLP = 1 USD worth of token)
        uint256 usdValue = _glpAmount;
        uint256 tokenAmount = _getTokenAmount(_token, usdValue);

        // Check if vault has sufficient balance
        if (tokenBalances[_token] < tokenAmount) {
            revert InsufficientBalance(tokenAmount, tokenBalances[_token]);
        }

        // Burn GLP tokens from user
        IGLPToken(glpToken).burn(msg.sender, _glpAmount);

        // Update vault's token balance tracking
        tokenBalances[_token] -= tokenAmount;

        // Transfer tokens from vault to user
        IERC20(_token).safeTransfer(msg.sender, tokenAmount);

        // Emit withdrawal event
        emit LiquidityWithdrawn(
            msg.sender,
            _token,
            tokenAmount,
            _glpAmount,
            usdValue
        );
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates the USD value of a token amount (placeholder implementation)
     * @param _token The address of the token
     * @param _amount The amount of tokens
     * @return usdValue The USD value of the token amount
     * @dev This is a placeholder implementation that assumes:
     *      - 1 USDC = $1 USD
     *      - 1 WETH = $2000 USD
     *      In production, this should integrate with a price oracle
     */
    function _getUSDValue(address _token, uint256 _amount) 
        internal 
        view 
        returns (uint256 usdValue) 
    {
        if (_token == USDC) {
            // Assuming USDC has 6 decimals and 1 USDC = $1
            // Convert from token decimals to USD (18 decimals)
            usdValue = (_amount * 1e18) / 1e6;
        } else if (_token == WETH) {
            // Assuming WETH has 18 decimals and 1 WETH = $2000
            // Already in 18 decimals, multiply by price
            usdValue = _amount * 2000;
        }
    }

    /**
     * @notice Calculates the token amount for a given USD value (placeholder implementation)
     * @param _token The address of the token
     * @param _usdValue The USD value to convert
     * @return tokenAmount The amount of tokens equivalent to the USD value
     * @dev This is a placeholder implementation that assumes:
     *      - 1 USDC = $1 USD
     *      - 1 WETH = $2000 USD
     *      In production, this should integrate with a price oracle
     */
    function _getTokenAmount(address _token, uint256 _usdValue) 
        internal 
        view 
        returns (uint256 tokenAmount) 
    {
        if (_token == USDC) {
            // Convert from USD (18 decimals) to USDC (6 decimals)
            tokenAmount = (_usdValue * 1e6) / 1e18;
        } else if (_token == WETH) {
            // Convert from USD to WETH using $2000 price
            tokenAmount = _usdValue / 2000;
        }
    }


    //  /*//////////////////////////////////////////////////////////////
    //                 CHAINLINK PRICE FEED FUNCTIONS
    // //////////////////////////////////////////////////////////////*/

    // /**
    //  * @notice Gets the latest price for a token from Chainlink price feeds
    //  * @param _token The address of the token to get price for
    //  * @return price The latest price in USD with 8 decimals (Chainlink standard)
    //  * @dev This function:
    //  *      1. Determines which price feed to use based on token
    //  *      2. Fetches latest round data from Chainlink
    //  *      3. Validates price data freshness (not stale)
    //  *      4. Validates price is positive
    //  *      5. Returns price in 8 decimal format
    //  * @custom:security Implements comprehensive price feed validation
    //  * @custom:security Checks for stale price data to prevent manipulation
    //  */
    // function _getTokenPrice(address _token) internal view returns (uint256 price) {
    //     AggregatorV3Interface priceFeed;
        
    //     // Select appropriate price feed
    //     if (_token == USDC) {
    //         priceFeed = usdcPriceFeed;
    //     } else if (_token == WETH) {
    //         priceFeed = ethPriceFeed;
    //     } else {
    //         revert TokenNotWhitelisted(_token);
    //     }

    //     // Get latest price data from Chainlink
    //     (
    //         uint80 roundId,
    //         int256 priceData,
    //         uint256 startedAt,
    //         uint256 updatedAt,
    //         uint80 answeredInRound
    //     ) = priceFeed.latestRoundData();

    //     // Validate price data freshness
    //     if (block.timestamp - updatedAt > PRICE_STALENESS_THRESHOLD) {
    //         revert StalePriceFeed(address(priceFeed), updatedAt, block.timestamp);
    //     }

    //     // Validate price is positive
    //     if (priceData <= 0) {
    //         revert InvalidPriceFeed(address(priceFeed), priceData);
    //     }

    //     // Ensure round data is complete
    //     require(updatedAt > 0 && answeredInRound >= roundId, "Invalid round data");

    //     return uint256(priceData);
    // }

    // /*//////////////////////////////////////////////////////////////
    //                       INTERNAL HELPER FUNCTIONS
    // //////////////////////////////////////////////////////////////*/

    // /**
    //  * @notice Calculates the USD value of a token amount using Chainlink price feeds
    //  * @param _token The address of the token
    //  * @param _amount The amount of tokens
    //  * @return usdValue The USD value of the token amount (18 decimals)
    //  * @dev This function:
    //  *      1. Gets real-time token price from Chainlink (8 decimals)
    //  *      2. Handles different token decimal places properly
    //  *      3. Converts to standardized 18 decimal USD value
    //  *      4. Accounts for token-specific decimal scaling
    //  * @custom:implementation USDC has 6 decimals, WETH has 18 decimals
    //  * @custom:implementation Chainlink prices have 8 decimals
    //  * @custom:implementation Final USD value uses 18 decimals for consistency
    //  */
    // function _getUSDValue(address _token, uint256 _amount) 
    //     internal 
    //     view 
    //     returns (uint256 usdValue) 
    // {
    //     // Get current token price (8 decimals from Chainlink)
    //     uint256 tokenPrice = _getTokenPrice(_token);
        
    //     if (_token == USDC) {
    //         // USDC: 6 decimals, Price: 8 decimals, Target: 18 decimals
    //         // Formula: (amount * price * 1e18) / (1e6 * 1e8)
    //         usdValue = (_amount * tokenPrice * 1e18) / (1e6 * 1e8);
    //     } else if (_token == WETH) {
    //         // WETH: 18 decimals, Price: 8 decimals, Target: 18 decimals  
    //         // Formula: (amount * price * 1e18) / (1e18 * 1e8)
    //         usdValue = (_amount * tokenPrice) / 1e8;
    //     }
    // }

    // /**
    //  * @notice Calculates the token amount for a given USD value using Chainlink price feeds
    //  * @param _token The address of the token
    //  * @param _usdValue The USD value to convert (18 decimals)
    //  * @return tokenAmount The amount of tokens equivalent to the USD value
    //  * @dev This function:
    //  *      1. Gets real-time token price from Chainlink (8 decimals)
    //  *      2. Converts USD value to token amount using current price
    //  *      3. Handles different token decimal places properly
    //  *      4. Returns amount in token's native decimal format
    //  * @custom:implementation USDC returned with 6 decimals, WETH with 18 decimals
    //  * @custom:implementation Uses division to prevent overflow in calculations
    //  */
    // function _getTokenAmount(address _token, uint256 _usdValue) 
    //     internal 
    //     view 
    //     returns (uint256 tokenAmount) 
    // {
    //     // Get current token price (8 decimals from Chainlink)
    //     uint256 tokenPrice = _getTokenPrice(_token);
        
    //     if (_token == USDC) {
    //         // USD: 18 decimals, Price: 8 decimals, Target: 6 decimals (USDC)
    //         // Formula: (usdValue * 1e6 * 1e8) / (1e18 * price)
    //         tokenAmount = (_usdValue * 1e6 * 1e8) / (1e18 * tokenPrice);
    //     } else if (_token == WETH) {
    //         // USD: 18 decimals, Price: 8 decimals, Target: 18 decimals (WETH)
    //         // Formula: (usdValue * 1e8) / price
    //         tokenAmount = (_usdValue * 1e8) / tokenPrice;
    //     }
    // }


    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the current balance of a specific token in the vault
     * @param _token The address of the token to query
     * @return balance The current balance of the token in the vault
     */
    function getTokenBalance(address _token) external view returns (uint256 balance) {
        return tokenBalances[_token];
    }

    /**
     * @notice Returns the total USD value of all assets in the vault (placeholder implementation)
     * @return totalValue The total USD value of all assets
     * @dev Calculates based on current token balances and placeholder prices
     */
    function getTotalValueLocked() external view returns (uint256 totalValue) {
        uint256 usdcValue = _getUSDValue(USDC, tokenBalances[USDC]);
        uint256 wethValue = _getUSDValue(WETH, tokenBalances[WETH]);
        return usdcValue + wethValue;
    }

    /**
     * @notice Returns whether a token is whitelisted for deposits/withdrawals
     * @param _token The address of the token to check
     * @return isWhitelisted True if the token is whitelisted, false otherwise
     */
    function getIsWhitelistedToken(address _token) external view returns (bool isWhitelisted) {
        return isWhitelistedToken[_token];
    }

    // /**
    //  * @notice Returns the current price of a token from Chainlink price feeds
    //  * @param _token The address of the token to get price for
    //  * @return price The current price in USD with 8 decimals
    //  * @dev Publicly accessible function to check current token prices
    //  */
    // function getTokenPrice(address _token) external view returns (uint256 price) {
    //     return _getTokenPrice(_token);
    // }

    // /**
    //  * @notice Returns the addresses of the Chainlink price feeds being used
    //  * @return usdcFeed Address of the USDC/USD price feed
    //  * @return ethFeed Address of the ETH/USD price feed
    //  * @dev Useful for verification and monitoring purposes
    //  */
    // function getPriceFeeds() external view returns (address usdcFeed, address ethFeed) {
    //     return (address(usdcPriceFeed), address(ethPriceFeed));
    // }
}
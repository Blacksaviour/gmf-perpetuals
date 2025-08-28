// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IFundingRateManager.sol";

/**
 * NOTE: This contract is a placeholder for the PoC.
 * In a full implementation, it would contain the complex logic for calculating and
 * settling funding rates to balance open interest. For this build, it is intentionally left empty.
 */
contract FundingRateManager is IFundingRateManager {
    function updateOpenInterest(
        address _token,
        bool _isLong,
        uint256 _sizeDelta
    ) external {
        // Intentionally empty for the PoC
    }

    function settleFunding(address _token) external {
        // Intentionally empty for the PoC
    }
}

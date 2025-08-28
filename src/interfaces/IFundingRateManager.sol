// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFundingRateManager {
    function updateOpenInterest(
        address _token,
        bool _isLong,
        uint256 _sizeDelta
    ) external;

    function settleFunding(address _token) external;
}

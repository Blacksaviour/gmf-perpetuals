// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPositionManager {
    function createPosition(
        address _account,
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _leverage,
        bool _isLong
    ) external;

    function closePosition(
        address _account,
        bytes32 _positionKey
    ) external returns (int256);

    function updateFunding(bytes32 _positionKey) external;
}

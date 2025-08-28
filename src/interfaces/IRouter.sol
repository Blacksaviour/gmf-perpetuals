// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouter {
    function openLongPosition(
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _leverage
    ) external;
    function openShortPosition(
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _leverage
    ) external;
    function closePosition(bytes32 _positionKey) external;
}

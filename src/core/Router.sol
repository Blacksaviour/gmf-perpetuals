// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IRouter.sol";

contract Router is IRouter {
    // TODO: Add state variables for Vault and PositionManager addresses
    // TODO: Implement a constructor to set the addresses

    function openLongPosition(
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _leverage
    ) external {
        // TODO: Implement logic to call PositionManager
    }

    function openShortPosition(
        address _indexToken,
        uint256 _collateralAmount,
        uint256 _leverage
    ) external {
        // TODO: Implement logic to call PositionManager
    }

    function closePosition(bytes32 _positionKey) external {
        // TODO: Implement logic to call PositionManager
    }
}

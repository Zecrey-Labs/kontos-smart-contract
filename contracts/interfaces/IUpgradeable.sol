// SPDX-License-Identifier: Apache-2.0 OR Apache-2.0
pragma solidity ^0.8.18;

/// @title Interface of the upgradeable contract
/// @author Kontos
interface IUpgradeable {
    /// @notice Upgrades target of upgradeable contract
    /// @param newTarget New target
    /// @param newTargetInitializationParameters New target initialization parameters
    function upgradeTarget(address newTarget, bytes calldata newTargetInitializationParameters) external;
}
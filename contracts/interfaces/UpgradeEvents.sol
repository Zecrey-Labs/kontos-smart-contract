// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title Upgrade events
/// @author Kontos Team
interface UpgradeEvents {
    /// @notice Event emitted when new upgradeable contract is added to upgrade gatekeeper's list of managed contracts
    event NewUpgradable(uint256 indexed versionId, address indexed upgradeable);

    /// @notice Upgrade mode enter event
    event NoticePeriodStart(
        bytes32 index,
        uint32 versionId,
        address newTarget,
        uint256 noticePeriod // notice period (in seconds)
    );

    /// @notice Upgrade mode cancel event
    event UpgradeCancel(uint256 indexed versionId);

    /// @notice Upgrade mode preparation status event
    event PreparationStart(uint256 indexed versionId);

    /// @notice Upgrade mode complete event
    event UpgradeComplete(bytes32 index, uint256 indexed versionId, address newTarget);
}

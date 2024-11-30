// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./core/BaseProxy.sol";
import "./interfaces/IProxy.sol";
import "./interfaces/UpgradeEvents.sol";

contract UpgradeGateKeeper is UpgradeEvents, IProxy, UpgradeableOwnable {

    /// @notice Upgrade mode statuses
    enum UpgradeStatus {
        Idle,
        NoticePeriod,
        Preparation
    }

    UpgradeStatus public upgradeStatus;
    uint256 public noticePeriod;
    /// @notice Notice period finish timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint256 public noticePeriodFinishTimestamp;


    mapping(bytes32 => IUpgradeable) public managedContracts;
    mapping(bytes32 => address) public nextTargets;
    /// @notice Version id of contracts
    uint256 public versionId;
    mapping(bytes32 => uint32) public versionIds;

    //    constructor(uint256 _noticePeriod) UpgradeableOwnable(msg.sender){
    //        noticePeriod = _noticePeriod;
    //    }

    bool private initOnce;

    function initialize(bytes calldata initializationParameters) external {
        require(!initOnce, "I");
        (uint256 _noticePeriod) = abi.decode(initializationParameters, (uint256));
        noticePeriod = _noticePeriod;
        setMaster(msg.sender);
        initOnce = true;
    }

    function upgrade(bytes calldata params) external {}

    function getManagedContractsByString(string calldata index) public view returns (address){
        bytes32 indexBytes32 = keccak256(abi.encode(index));
        return address(managedContracts[indexBytes32]);
    }

    function addUpgradeable(bytes32 _nameHash, IUpgradeable _proxy) external {
        requireMaster(msg.sender);
        require(address(managedContracts[_nameHash]) == address(0), "E");
        managedContracts[_nameHash] = _proxy;
    }

    function startUpgrade(bytes32[] memory _indexes, address[] memory _targets) external {
        requireMaster(msg.sender);
        require(_indexes.length == _targets.length, "spu10");
        // spu11 - unable to activate active upgrade mode
        require(upgradeStatus == UpgradeStatus.Idle, "spu11");

        // this noticePeriod is a configurable shortest notice period
        upgradeStatus = UpgradeStatus.NoticePeriod;
        noticePeriodFinishTimestamp = block.timestamp + noticePeriod;
        for (uint256 i = 0; i < _indexes.length; i++) {
            require(address(managedContracts[_indexes[i]]) != address(0), "spu12");
            nextTargets[_indexes[i]] = _targets[i];
            emit NoticePeriodStart(_indexes[i], versionIds[_indexes[i]], _targets[i], noticePeriod);
        }
    }

    /// @notice Cancels upgrade
    function cancelUpgrade(bytes32 _index) external {
        requireMaster(msg.sender);
        require(upgradeStatus != UpgradeStatus.Idle, "cpu11");
        // cpu11 - unable to cancel not active upgrade mode

        upgradeStatus = UpgradeStatus.Idle;
        noticePeriodFinishTimestamp = 0;
        delete nextTargets[_index];
        emit UpgradeCancel(versionIds[_index]);
    }

    /// @notice Activates preparation status
    function startPreparation() external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.NoticePeriod, "ugp11");
        // ugp11 - unable to activate preparation status in case of not active notice period status
        require(block.timestamp >= noticePeriodFinishTimestamp, "ugp12");
        // upg12 - shortest notice period not passed

        upgradeStatus = UpgradeStatus.Preparation;
        emit PreparationStart(versionId);
    }

    /// @notice Finishes upgrade
    /// @param targetsUpgradeParameters New targets upgrade parameters per each upgradeable contract
    function finishUpgrade(bytes32[] calldata _indexes, bytes[] calldata targetsUpgradeParameters) external {
        requireMaster(msg.sender);
        require(_indexes.length == targetsUpgradeParameters.length, "fpu10");
        require(upgradeStatus == UpgradeStatus.Preparation, "fpu11");

        for (uint64 i = 0; i < _indexes.length; i++) {
            bytes32 index = _indexes[i];
            if (nextTargets[index] != address(0)) {
                managedContracts[index].upgradeTarget(nextTargets[index], targetsUpgradeParameters[i]);
            }
            versionIds[index]++;
            emit UpgradeComplete(index, versionIds[index], nextTargets[index]);
            delete nextTargets[index];
        }

        upgradeStatus = UpgradeStatus.Idle;
        noticePeriodFinishTimestamp = 0;
    }

}

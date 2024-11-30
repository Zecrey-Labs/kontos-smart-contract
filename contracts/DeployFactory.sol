// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "./EntryPoint.sol";
import "./Secp256r1ECDSA.sol";
import "./core/BaseProxy.sol";
import "./SmartAccountFactory.sol";
import "./SmartAccount.sol";
import "./UpgradeGateKeeper.sol";

contract DeployFactory {

    SmartAccountBeacon public beacon;
    BaseProxy public upgradeGateKeeperProxy;

    address private owner;
    address private superOwner;

    constructor(address _owner, address _superOwner) {
        require(_owner != address(0) && _superOwner != address(0), "CAIV0");
        owner = _owner;
        superOwner = _superOwner;
    }

    modifier onlySuperOwner{
        require(msg.sender == superOwner, "NSO");
        _;
    }

    function newOwner(address _owner) onlySuperOwner external {
        require(_owner != address(0), "CAIV1");
        owner = _owner;
    }

    function newSuperOwner(address _superOwner) onlySuperOwner external {
        require(_superOwner != address(0), "CAIV2");
        superOwner = _superOwner;
    }

    function getProxyCreationByteCode(address _target, bytes memory _initParams) public pure returns (bytes memory) {
        bytes memory bytecode = type(BaseProxy).creationCode;
        return abi.encodePacked(bytecode, abi.encode(_target, _initParams));
    }

    function _salt() internal pure returns (bytes32){
        return keccak256(abi.encode("kontos"));
    }

    function create2(bytes memory code, bytes32 salt) internal returns (address) {
        address payable deployedAddress;
        assembly{
            deployedAddress := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(deployedAddress)) {
                revert(0, 0)
            }
        }
        return deployedAddress;
    }

    function initSmartAccountBeacon(address _beacon) onlyOwner external {
        if (address(beacon) == address(0)) {
            beacon = SmartAccountBeacon(_beacon);
        }
    }

    function initUpgradeGateKeeper(address _gateKeeper, bytes memory _initParams) onlyOwner external {
        if (address(upgradeGateKeeperProxy) == address(0)) {
            bytes memory code = getProxyCreationByteCode(_gateKeeper, _initParams);
            address deployedAddress = create2(code, _salt());
            upgradeGateKeeperProxy = BaseProxy(payable(deployedAddress));
        }
    }

    function initProxy(address _contractAddress, string memory _index, bytes memory _initParams) onlyOwner external {
        bytes memory code = getProxyCreationByteCode(_contractAddress, _initParams);
        bytes32 indexBytes = keccak256(abi.encode(_index));
        //require(address(UpgradeGateKeeper(payable(address(_upgradeGateKeeperProxy))).managedContracts(indexBytes)) != address(0), 'IPE');
        address deployedProxyAddress = create2(code, _salt());
        BaseProxy _proxy = BaseProxy(payable(deployedProxyAddress));
        // transferOwnership
        _proxy.transferMastership(address(upgradeGateKeeperProxy));
        // add managedContracts
        UpgradeGateKeeper(payable(address(upgradeGateKeeperProxy))).addUpgradeable(indexBytes, _proxy);
    }

    modifier onlyOwner{
        require(msg.sender == owner, "NO");
        _;
    }

    function upgradeBeaconImpl(address _newImpl) onlyOwner external {
        beacon.update(_newImpl);
    }

    function upgradeGateKeeper(address _newTarget, bytes memory _newParams) onlyOwner external {
        upgradeGateKeeperProxy.upgradeTarget(_newTarget, _newParams);
    }

    function addUpgradeable(bytes32 _index, IUpgradeable _proxy) onlyOwner external {
        UpgradeGateKeeper(payable(address(upgradeGateKeeperProxy))).addUpgradeable(_index, _proxy);
    }

    function startUpgrade(bytes32[] memory _indexes, address[] memory _targets) onlyOwner external {
        UpgradeGateKeeper(payable(address(upgradeGateKeeperProxy))).startUpgrade(_indexes, _targets);
    }

    function cancelUpgrade(bytes32 _index) onlyOwner external {
        UpgradeGateKeeper(payable(address(upgradeGateKeeperProxy))).cancelUpgrade(_index);
    }

    function startPreparation() onlyOwner external {
        UpgradeGateKeeper(payable(address(upgradeGateKeeperProxy))).startPreparation();
    }

    function finishUpgrade(bytes32[] calldata _indexes, bytes[] calldata targetsUpgradeParameters) onlyOwner external {
        UpgradeGateKeeper(payable(address(upgradeGateKeeperProxy))).finishUpgrade(_indexes, targetsUpgradeParameters);
    }
}

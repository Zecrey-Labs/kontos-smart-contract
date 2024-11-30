// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "./core/BaseSmartAccountFactory.sol";
import "./core/BaseProxy.sol";
import "./SmartAccountBeacon.sol";
import "./interfaces/IKontosLightNode.sol";

contract SmartAccountFactory is BaseSmartAccountFactory, IProxy, Initializable {
    mapping(address => ISmartAccount) public accounts;
    IEntryPoint public entryPoint;
    IKontosLightNode public kontosLightNode;
    SmartAccountBeacon beacon;

    function initialize(bytes calldata initializationParameters) external override initializer {
        (address _kontosLightClient) = abi.decode(initializationParameters, (address));
        kontosLightNode = IKontosLightNode(_kontosLightClient);
    }

    function initBeacon(SmartAccountBeacon _beacon) external {
        if (address(beacon) == address(0)) {
            beacon = _beacon;
        }
    }

    function getBeacon() external view returns (address){
        return address(beacon);
    }

    function initEntryPoint(IEntryPoint _entryPoint) external {
        if (address(entryPoint) == address(0x0)) {
            entryPoint = _entryPoint;
        }
    }

    function upgrade(bytes calldata params) external override {
        address _beacon = abi.decode(params,(address));
        beacon = SmartAccountBeacon(_beacon);
    }

    function parseInitCode(bytes calldata _initCode) public pure returns (uint256[2] memory){
        (uint256[2] memory pk) = abi.decode(_initCode, (uint256[2]));
        return (pk);
    }

    function _requireFromEntryPoint() internal view {
        require(msg.sender == address(entryPoint), "account factory: not from EntryPoint");
    }

    event NewAccount(address _nameAddr, address _aaAddr);

    function create2(bytes memory code, bytes32 salt) internal returns (address) {
        address payable deployedAddress;
        assembly{
            deployedAddress := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(deployedAddress)) {
                revert(0, "create2 fail")
            }
        }
        return deployedAddress;
    }

    function createSmartAccount(address _nameAddr, bytes calldata _initCode) external override returns (address) {
        _requireFromEntryPoint();
        require(address(accounts[_nameAddr]) == address(0), "account exists");
        (uint256[2] memory pk) = parseInitCode(_initCode);
        bytes memory initParams = abi.encode(_nameAddr);
        bytes memory bytecode = type(BeaconProxy).creationCode;
        bytes memory deployData = abi.encodePacked(bytecode, abi.encode(address(beacon), abi.encodeWithSelector(SmartAccount(payable(address(0))).initialize.selector, initParams)));
        BeaconProxy accountBeacon = BeaconProxy(payable(create2(deployData, keccak256(abi.encodePacked(_nameAddr)))));
        accounts[_nameAddr] = ISmartAccount(address(accountBeacon));
        accounts[_nameAddr].initPubKey(pk);
        emit NewAccount(_nameAddr, address(accountBeacon));
        return address(accountBeacon);
    }

    function _requireFromEntryPointOrMigrateHelper() internal view {
        require(msg.sender == address(entryPoint), "NFEOM");
    }

    function updateAccount(address _nameAddr, address _beacon, uint256[2] memory _pk) external {
        // only can be accessed by V2
        _requireFromEntryPointOrMigrateHelper();
        if (!hasAccount(_nameAddr)) {
            accounts[_nameAddr] = ISmartAccount(address(_beacon));
            accounts[_nameAddr].initPubKey(_pk);
            emit NewAccount(_nameAddr, address(_beacon));
        } else {
            // TODO record old aa address
            if (address(accounts[_nameAddr]) != _beacon) {
                accounts[_nameAddr] = ISmartAccount(address(_beacon));
            }
            uint256[2] memory existPk = accounts[_nameAddr].pubKey();
            if (existPk[0] != _pk[0] || existPk[1] != _pk[1]) {
                accounts[_nameAddr].updatePubKey(_pk);
                emit NewAccount(_nameAddr, address(_beacon));
            }
        }
    }

    function hasAccount(address _addr) public view override returns (bool){
        return address(accounts[_addr]) != address(0);
    }

    function getSmartAccount(address _addr) public view override returns (ISmartAccount){
        return accounts[_addr];
    }

    function nameAddress(string calldata _name) public pure override returns (address){
        return super.nameAddress(_name);
    }

    function sigSize() external pure returns (uint256){
        return 64;
    }

}

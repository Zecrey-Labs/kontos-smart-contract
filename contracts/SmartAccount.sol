// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "./core/BaseSmartAccount.sol";
import "./SmartAccountFactory.sol";
import "./interfaces/IProxy.sol";
import "./interfaces/IKontosLightNode.sol";

contract SmartAccount is BaseSmartAccount, IProxy, Initializable, IERC721Receiver, IERC1155Receiver, IERC1271 {

    uint256[2] private _pk;
    uint64 private _nonce;
    address private _kontosAddress;
    IEntryPoint private _entryPoint;
    IKontosLightNode private _kontosLightNode;
    bytes private _slot;

    receive() external payable {}

    function isValidSignature(bytes32, bytes memory) external override pure returns (bytes4 magicValue){
        return this.isValidSignature.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override pure returns (bytes4){
        return this.onERC721Received.selector;
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override pure returns (bytes4){
        return this.onERC1155Received.selector;
    }

    function supportsInterface(bytes4 _id) external override pure returns (bool){
        if (_id == this.executeBatch.selector || _id == this.nonce.selector || _id == this.pubKey.selector ||
        _id == this.prePay.selector || _id == this.compensate.selector || _id == this.kontosAddress.selector ||
        _id == this.updatePubKey.selector || _id == this.initPubKey.selector || _id == this.onERC721Received.selector || _id == this.onERC1155Received.selector ||
        _id == this.onERC1155BatchReceived.selector || _id == this.kontosLightClient.selector || _id == this.isValidSignature.selector) {
            return true;
        }
        return false;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external override pure returns (bytes4){
        return this.onERC1155BatchReceived.selector;
    }

    function nonce() external override view returns (uint64){
        return _nonce;
    }

    function kontosAddress() external override view returns (address){
        return _kontosAddress;
    }

    function entryPoint() public view override returns (IEntryPoint){
        if (address(_entryPoint) == address(0)) {
            return IEntryPoint(address(0x922451e6144A10fC235c15952e6357827824D3c3));
        }
        return _entryPoint;
    }

    function kontosLightClient() public view returns (IKontosLightNode){
        if (address(_kontosLightNode) == address(0)) {
            return IKontosLightNode(address(0x87a1406bAF001812db13e4A7D8A6cf7E2Dc6F926));
        }
        return _kontosLightNode;
    }

    function initialize(bytes calldata initializationParameters) external override initializer {
        (address __kontosAddress) = abi.decode(initializationParameters, (address));
        require(__kontosAddress != address(0), "S0");
        _kontosAddress = __kontosAddress;
    }

    function upgrade(bytes calldata params) external override {
    }

    event FailedAction(uint256 _index, bytes _revertReason);

    function addressToBytes32(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    function depositGas() external {
    }

    function executeBatch(ExecuteAction[] calldata _actions, bytes calldata, uint64 __nonce) external payable override {
        require(msg.sender == address(entryPoint()), "IVS");
        // take action
        for (uint256 i = 0; i < _actions.length; i++) {
            _call(_actions[i].dest, _actions[i].value, _actions[i].funcAndData);
        }
        // update nonce
        _nonce = __nonce;
    }

    function _call(address _target, uint256 _value, bytes memory _data) internal {
        (bool success, bytes memory result) = _target.call{value: _value}(_data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function pubKey() external override view returns (uint256[2] memory){
        return _pk;
    }

    function updatePubKey(uint256[2] memory __pk) external {
        _requireFromEntryPoint();
        if (__pk[0] != _pk[0] || __pk[1] != _pk[1]) {
            _pk = __pk;
        }
    }

    function initPubKey(uint256[2] memory __pk) external override {
        require(_pk[0] == 0 && _pk[1] == 0, "AI");
        _pk = __pk;
    }

    function _prePay(address _receiver, AssetInfo memory _asset) internal override {
        super._prePay(_receiver, _asset);
    }

    function _requireFromEntryPoint() internal override view {
        super._requireFromEntryPoint();
    }
}

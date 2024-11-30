// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "./UserOperation.sol";

interface ISmartAccount {

    enum AccountType{
        Regular,
        MultiSig,
        Lender
    }

    struct SlotData {
        AccountType accountType;
        bool isLocked;
        address lenderEmergencyOperator;
        address[] lenderBrokerList;
    }

    struct ExecuteAction {
        address dest;
        uint256 value;
        bytes funcAndData;
    }

    function executeBatch(ExecuteAction[] calldata _actions, bytes memory _sigOrProof, uint64 _nonce) external payable;

    function nonce() external view returns (uint64);

    function pubKey() external view returns (uint256[2] memory);

    function prePay(address _receiver, AssetInfo memory _asset) external payable;

    function compensate(address _receiver, uint256 _fund) external payable;

    function kontosAddress() external view returns (address);

    function updatePubKey(uint256[2] memory _pk) external;

    function initPubKey(uint256[2] memory _pk) external;

}

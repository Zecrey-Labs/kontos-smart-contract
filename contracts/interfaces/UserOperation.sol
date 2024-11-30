// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

/* solhint-disable no-inline-assembly */

    enum ActionByCode{
        BY_BROKER,
        BY_OWNER,
        BY_PROOF
    }

    struct SinglePayment {
        address payer;
        uint256 amount;
    }

    struct PaymentData {
        address assetAddress;
        SinglePayment[] payments;
    }

    struct UserOperationWithPayment {
        UserOperation userOperation;
        PaymentData[] paymentData;
    }

    struct UserOpPayment {
        uint256 chainIndex;
        bytes assetAddress;
        uint256 assetAmount;
    }

    struct UserOpPayments {
        UserOpPayment[] successfulPayments;
        UserOpPayment[] failPayments;
    }

    struct UserOperation {
        address sender;
        uint64 nonce;
        uint64 validUntil;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        AssetInfo[] requiredAssets;
        bytes sigOrProof;
        // operator address + signature
        bytes fundInfo;
    }

    struct AssetInfo {
        address assetAddress;
        uint256 amount;
    }

    struct UniqueAsset {
        string chainIndex;
        address assetAddress;
        uint256 assetAmount;
    }

library UserOperationLib {

    address public constant NativeAsset = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    enum OperationStatus{
        Success,
        FailAtNewAccount,
        FailAtPrePay,
        FailAtExecuteTx
    }

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        return abi.encode(
            userOp.sender,
            userOp.nonce,
            userOp.initCode,
            userOp.callData,
            userOp.callGasLimit,
            userOp.requiredAssets,
            userOp.validUntil
        );
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

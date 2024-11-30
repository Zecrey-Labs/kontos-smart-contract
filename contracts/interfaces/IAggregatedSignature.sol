// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IAggregatedSignature {

    struct SigInfo {
        uint256[2] pubKey;
        bytes32 msgHash;
        bytes signature;
    }

    struct ProofWithPubInput {
        uint256[8] proof;
        uint256[1] pubInput;
    }

    function verifyByZk(SigInfo[] memory _sigInfos, uint256 _count, ProofWithPubInput calldata _proofWithPubInput) external view;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../core/KontosProofHelper.sol";

interface IKontosLightNode {

    struct LightHeader {
        bytes32 blockHash;
        uint64 height;
    }

    function verifyKontosProofAndUpdateHeaders(KontosProofHelper.AggregatedKontosProof calldata _proof) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "../core/KontosProofHelper.sol";

interface OldIKontosLightNode {

    struct LightHeader {
        bytes32 blockHash;
        uint64 height;
    }

    struct ZKProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
    }

    function verifyMembershipProof(bytes memory _membershipProof) external view returns (bool success);

    function updateBlockHeaders(bytes memory _blockHeaders) external;

}

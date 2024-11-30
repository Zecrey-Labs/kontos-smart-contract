// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./interfaces/IAggregatedSignature.sol";
import "./interfaces/IProxy.sol";
import "./Secp256r1Verifier.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Secp256r1ECDSA is IAggregatedSignature, IProxy, Initializable {

    uint256 private cap;

    function initialize(bytes calldata initializationParameters) external initializer {
        (uint256 _cap) = abi.decode(initializationParameters, (uint256));
        cap = _cap;
    }

    function upgrade(bytes calldata params) external {}

    function p256ScalarField() private pure returns (uint256){
        return 0xffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551;
    }


    function verifyByZk(SigInfo[] memory _sigInfos, uint256 _count, ProofWithPubInput calldata _proofWithPubInput) external view override {
        //return;
        require(_count <= cap, "overflow");
        // construct public input
        bytes memory hashData;
        for (uint256 i = 0; i < _count; i++) {
            SigInfo memory sigInfo = _sigInfos[i];
            uint256 msgHash = uint256(sigInfo.msgHash) % p256ScalarField();
            if (i == 0) {
                hashData = abi.encodePacked(msgHash, sigInfo.pubKey[0], sigInfo.pubKey[1]);
            } else {
                hashData = abi.encodePacked(hashData, msgHash, sigInfo.pubKey[0], sigInfo.pubKey[1]);
            }
        }
        uint256 SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        uint256 hashVal = uint256(keccak256(hashData)) % SNARK_SCALAR_FIELD;
        require(_proofWithPubInput.pubInput[0] == hashVal, "IVPI");
        Secp256r1Verifier.verifyProof(_proofWithPubInput.proof, _proofWithPubInput.pubInput);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./KontosLightClientStorage.sol";
import "./interfaces/IProxy.sol";
import "./interfaces/ISmartAccount.sol";
import "./interfaces/IKontosLightNode.sol";
import "./AggregatedKontosProofVerifier.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KontosLightClient is IKontosLightNode, KontosLightClientStorage, IProxy, Initializable {

    event NewBlock(uint64 height, bytes32 blockHash);

    uint256 private constant BLS12377_SCALAR_FIELD = 0x12ab655e9a2ca55660b44d1e5c37b00159aa76fed00000010a11800000000001;
    address private constant ENTRY_POINT_1 = 0xa0dBdB0767aFDb382322715A85E877B0f4E08fCf;
    address private constant ENTRY_POINT_2 = 0x5f13d26f40516D7791eA8E38B6C507bf399e8C6b;

    function initialize(bytes calldata initializationParameters) external override initializer {}

    function upgrade(bytes calldata params) external override {}

    function isProofUsed(bytes32 _pairHash) public view returns (bool) {
        return provedStoragePair[_pairHash];
    }

    function updateUsedProof(bytes32 _pairHash) internal {
        provedStoragePair[_pairHash] = true;
    }

    function updateUsedProofByEntryPoint(bytes32 _opHash) external {
        require(msg.sender == ENTRY_POINT_1, "INE");
        provedStoragePair[_opHash] = true;
    }

    function aggregatedProofDataHash(KontosProofHelper.AggregatedKontosProof memory _proof)
        internal
        view
        returns (bytes32, IKontosLightNode.LightHeader[] memory)
    {
        uint256 size = _proof.lightHeaderWithProofsArr.length;
        bytes memory hashData;
        IKontosLightNode.LightHeader[] memory lightHeaders = new IKontosLightNode.LightHeader[](size);

        for (uint256 i = 0; i < size; ) {
            KontosProofHelper.LightHeaderWithProofs memory lightHeaderWithProof = _proof.lightHeaderWithProofsArr[i];
            IKontosLightNode.LightHeader memory lightHeader = lightHeaderWithProof.lightBlockHash;
            lightHeaders[i] = lightHeader;

            hashData = abi.encodePacked(hashData, uint256(lightHeader.height), lightHeader.blockHash);

            uint256 eProofSize = lightHeaderWithProof.kontosStoragePairs.length;
            for (uint256 j = 0; j < eProofSize; ) {
                KontosProofHelper.KontosStoragePair memory storagePair = lightHeaderWithProof.kontosStoragePairs[j];
                require(storagePair.storageKey.length % 32 == 0, "IVK");
                require(storagePair.storageValue.length % 32 == 0, "IVV");
                hashData = abi.encodePacked(hashData, storagePair.storageKey, storagePair.storageValue);
                unchecked { j++; }
            }
            unchecked { i++; }
        }

        bytes32 baseHeaderHash = kontosStorageSimHeaders[_proof.headerBaseHeight];
        if (tip != 0) {
            require(baseHeaderHash != bytes32(0), "IVB");
        }

        hashData = abi.encodePacked(
            hashData,
            baseHeaderHash,
            _proof.headerAuxData[0],
            _proof.headerAuxData[1],
            _proof.headerAuxData[2],
            _proof.headerAuxData[3],
            _proof.headerAuxData[4]
        );

        return (keccak256(hashData), lightHeaders);
    }

    function verifyKontosProofAndUpdateHeaders(KontosProofHelper.AggregatedKontosProof calldata _proof) external override {
        require(msg.sender == ENTRY_POINT_1 || msg.sender == ENTRY_POINT_2, "NE");

        for (uint256 i = 0; i < _proof.lightHeaderWithProofsArr.length; ) {
            KontosProofHelper.LightHeaderWithProofs memory _lhWithProof = _proof.lightHeaderWithProofsArr[i];

            for (uint256 j = 0; j < _lhWithProof.kontosStoragePairs.length; ) {
                KontosProofHelper.KontosStoragePair memory pair = _lhWithProof.kontosStoragePairs[j];
                bytes32 pairHash = keccak256(abi.encode(pair.storageKey, pair.storageValue));
                require(!isProofUsed(pairHash), "UP");
                updateUsedProof(pairHash);
                unchecked { j++; }
            }
            unchecked { i++; }
        }

        (bytes32 aggregatedDataHash, IKontosLightNode.LightHeader[] memory lightHeaders) = aggregatedProofDataHash(_proof);

        require(
            _proof.dataHash[0] == uint256(aggregatedDataHash) % BLS12377_SCALAR_FIELD,
            "NMDH"
        );

        AggregatedKontosProofVerifier.verifyProof(_proof.proof, _proof.dataHash);

        updateBlockHeaders(_proof.headerBaseHeight, lightHeaders);
    }

    function updateBlockHeaders(uint64 _baseHeight, LightHeader[] memory _lightBlockHashes) internal {
        uint64 lastHeight = _baseHeight;

        for (uint256 i = 0; i < _lightBlockHashes.length; ) {
            LightHeader memory lightHeader = _lightBlockHashes[i];
            require(lightHeader.height >= lastHeight, "IVH1");

            bytes32 headerHash = bytes32(uint256(lightHeader.blockHash) % BLS12377_SCALAR_FIELD);
            if (kontosStorageSimHeaders[lightHeader.height] != bytes32(0)) {
                require(headerHash == kontosStorageSimHeaders[lightHeader.height], "IVH2");
            }

            kontosStorageSimHeaders[lightHeader.height] = headerHash;
            lastHeight = lightHeader.height;

            emit NewBlock(lastHeight, lightHeader.blockHash);

            unchecked { i++; }
        }

        if (lastHeight > tip) {
            tip = lastHeight;
        }
    }
}

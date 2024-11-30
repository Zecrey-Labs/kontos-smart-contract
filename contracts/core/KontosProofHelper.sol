// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "../interfaces/UserOperation.sol";
import "../interfaces/IKontosLightNode.sol";

library KontosProofHelper {

    enum ProofType{
        NEW_REGULAR_ACCOUNT,
        NEW_MULTI_SIG_ACCOUNT,
        NEW_LENDER_ACCOUNT,
        ACCOUNT_UPDATE_PUB_KEY,
        LENDER_REDEEM,
        LENDER_UPDATE_BROKER_LIST,
        LENDER_UPDATE_EMERGENCY_OPERATOR,
        REWARDS_DISTRIBUTION,
        OPERATION_TASK,
        CONNECTED
    }

    struct ProofTask {
        bytes32 opHash;
        uint256 chainIndex;
        address sender;
        address target;
        uint64 callGasLimit;
        bytes data;
        uint32 proofType;
    }

    struct ProofNewLenderAccount {
        address lenderEmergencyOperator;
        address[] lenderBrokerList;
    }

    struct ProofAccountPubKey {
        address nameAddress;
        uint256[2] pk;
    }

    struct Share {
        address assetAddress;
        uint256 occupiedPercent;
    }

    struct ProofLenderRedeem {
        address lender;
        Share[] shares;
    }

    struct ProofLenderUpdateBrokerList {
        address lender;
        address[] brokerList;
    }

    struct ProofLenderUpdateEmergencyOperator {
        address lender;
        address emergencyOperator;
    }

    struct RewardRecord {
        address receiver;
        AssetInfo[] assets;
    }

    struct ProofRewardDistribution {
        address payer;
        AssetInfo[] assets;
        RewardRecord[] rewards;
    }

    struct RawPaymentAsset {
        address payer;
        uint256 chainIndex;
        address assetAddress;
        uint256 assetAmount;
    }

    struct ProofOperationTask {
        address sender;
    }

    struct KontosStoragePair {
        bytes storageKey;
        bytes storageValue;
    }

    struct LightHeaderWithProofs {
        IKontosLightNode.LightHeader lightBlockHash;
        KontosStoragePair[] kontosStoragePairs;
    }

    struct AggregatedKontosProof {
        uint64 headerBaseHeight;
        uint256[5] headerAuxData;
        LightHeaderWithProofs[] lightHeaderWithProofsArr;
        uint256[8] proof;
        uint256[1] dataHash;
    }

    struct ProofConnected {
        address sender;
        uint256 sourceChainId;
        uint256 targetChainId;
        address connector;
        bytes data;
    }

    function encodeProofTask(ProofTask memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeProofTask(bytes memory data) internal pure returns (ProofTask memory){
        (ProofTask memory res) = abi.decode(data, (ProofTask));
        return res;
    }

    function encodeProofNewLenderAccount(ProofNewLenderAccount memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeProofNewLenderAccount(bytes memory data) internal pure returns (ProofNewLenderAccount memory){
        (ProofNewLenderAccount memory res) = abi.decode(data, (ProofNewLenderAccount));
        return res;
    }

    function encodeProofAccountPubKey(ProofAccountPubKey memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeProofAccountPubKey(bytes memory data) internal pure returns (ProofAccountPubKey memory){
        (ProofAccountPubKey memory res) = abi.decode(data, (ProofAccountPubKey));
        return res;
    }

    function encodeProofLenderRedeem(ProofLenderRedeem memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeProofLenderRedeem(bytes memory data) internal pure returns (ProofLenderRedeem memory){
        (ProofLenderRedeem memory res) = abi.decode(data, (ProofLenderRedeem));
        return res;
    }

    function encodeProofLenderUpdateBrokerList(ProofLenderUpdateBrokerList memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeProofLenderUpdateBrokerList(bytes memory data) internal pure returns (ProofLenderUpdateBrokerList memory){
        (ProofLenderUpdateBrokerList memory res) = abi.decode(data, (ProofLenderUpdateBrokerList));
        return res;
    }

    function encodeProofLenderUpdateEmergencyOperator(ProofLenderUpdateEmergencyOperator memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeProofLenderUpdateEmergencyOperator(bytes memory data) internal pure returns (ProofLenderUpdateEmergencyOperator memory){
        (ProofLenderUpdateEmergencyOperator memory res) = abi.decode(data, (ProofLenderUpdateEmergencyOperator));
        return res;
    }

    function encodeProofRewardDistribution(ProofRewardDistribution[] memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeProofRewardDistributions(bytes memory data) internal pure returns (ProofRewardDistribution[] memory){
        (ProofRewardDistribution[] memory res) = abi.decode(data, (ProofRewardDistribution[]));
        return res;
    }

    function encodeRawPaymentAssets(RawPaymentAsset[] memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeRawPaymentAssets(bytes memory data) internal pure returns (RawPaymentAsset[] memory){
        (RawPaymentAsset[] memory res) = abi.decode(data, (RawPaymentAsset[]));
        return res;
    }

    function encodeAggregatedKontosProof(AggregatedKontosProof memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeAggregatedKontosProof(bytes memory data) internal pure returns (AggregatedKontosProof memory){
        (AggregatedKontosProof memory res) = abi.decode(data, (AggregatedKontosProof));
        return res;
    }

    function encodeProofConnected(ProofConnected memory data) internal pure returns (bytes memory){
        return abi.encode(data);
    }

    function decodeProofConnected(bytes memory data) internal pure returns (ProofConnected memory){
        (ProofConnected memory res) = abi.decode(data, (ProofConnected));
        return res;
    }
}

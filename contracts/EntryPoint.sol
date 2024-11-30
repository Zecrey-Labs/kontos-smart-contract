// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./core/BaseEntryPoint.sol";
import "./interfaces/IProxy.sol";
import "./KontosLightClient.sol";
import "./SmartAccountFactory.sol";
import "./interfaces/IAggregatedSignature.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./core/KontosProofHelper.sol";

// contract EntryPoint is IProxy, BaseEntryPoint, Initializable, ReentrancyGuard {
contract EntryPoint is IProxy, BaseEntryPoint, Initializable {
    using UserOperationLib for UserOperation;
    SmartAccountFactory public accountFactory;
    mapping(address => bool) public brokerStatus;
    mapping(address => uint256) public strandedAssets;
    KontosLightClient public kontosLightNode;

    IAggregatedSignature public sigVerifier;

    struct ExecutionRes {
        UserOperationLib.OperationStatus status;
        address accountAddr;
        uint256 executedAt;
        uint256 actualGasCost;
        bytes revertReason;
    }

    struct ExecutionData {
        bytes32 opHash;
        ExecutionRes executionRes;
        PaymentData[] paymentData;
        address gasPayer;
        uint256 gasPrice;
    }

    event OpExecution(ExecutionData _return);

    struct ExecuteOpData {
        UserOperationLib.OperationStatus status;
        address accountProxyAddress;
        bytes revertRes;
        uint256 actualGasCost;
    }

    receive() external payable {}

    function initialize(bytes calldata initializationParameters) external override initializer {
        (address _accountFactory,address _sigVerifier,address _kontosLightNode) = abi.decode(initializationParameters, (address, address, address));
        accountFactory = SmartAccountFactory(_accountFactory);
        accountFactory.initEntryPoint(IEntryPoint(address(this)));
        sigVerifier = IAggregatedSignature(_sigVerifier);
        kontosLightNode = KontosLightClient(_kontosLightNode);
    }

    function upgrade(bytes calldata params) external override {
    }

    function getUserOpHashV2(UserOperation calldata _userOp) public view override returns (bytes32){
        return keccak256(abi.encode(_userOp.hash(), address(this), block.chainid));
    }

    function getUserOpHash(UserOperation calldata _userOp) public view override returns (bytes32){
        bytes memory userOpData = abi.encode(
            _userOp.sender,
            _userOp.nonce,
            _userOp.initCode,
            _userOp.callData,
            _userOp.callGasLimit,
            _userOp.requiredAssets,
            _userOp.validUntil,
            _userOp.fundInfo
        );
        return keccak256(abi.encode(keccak256(userOpData), address(this), block.chainid));
    }

    function decodePayments(bytes memory _fundInfo) public pure returns (UserOpPayments memory){
        UserOpPayments memory payments = abi.decode(_fundInfo, (UserOpPayments));
        return payments;
    }

    event Payment(address payer, bytes32 opHash, uint256 chainIndex, bytes assetAddress, uint256 assetAmount);

    function _handlePayments(address _payer, bytes32 _opHash, bytes memory _fundInfo, bool _successful) internal {
        if (_fundInfo.length != 0) {
            UserOpPayments memory payments = decodePayments(_fundInfo);
            if (_successful) {
                for (uint256 i = 0; i < payments.successfulPayments.length; i++) {
                    UserOpPayment memory payment = payments.successfulPayments[i];
                    emit Payment(_payer, _opHash, payment.chainIndex, payment.assetAddress, payment.assetAmount);
                }
            } else {
                for (uint256 i = 0; i < payments.failPayments.length; i++) {
                    UserOpPayment memory payment = payments.failPayments[i];
                    emit Payment(_payer, _opHash, payment.chainIndex, payment.assetAddress, payment.assetAmount);
                }
            }
        }
    }

    function preValidateUserOp(ISmartAccount _broker, UserOperation calldata _userOp) public view override returns (uint256[2] memory userPubKey) {
        if (_userOp.initCode.length != 0) {
            userPubKey = abi.decode(_userOp.initCode, (uint256[2]));
        } else {
            ISmartAccount account = accountFactory.getSmartAccount(_userOp.sender);
            require(address(account) != address(0), "A1");
            userPubKey = account.pubKey();
        }
        require(_userOp.requiredAssets.length != 0 || _userOp.initCode.length != 0 || _userOp.callData.length != 0, "A2");
        require(_userOp.validUntil > block.timestamp, "A3");
        require(_userOp.sigOrProof.length == accountFactory.sigSize(), "A4");
        AssetInfo[] memory requiredAssets = _userOp.requiredAssets;
        for (uint256 i = 0; i < requiredAssets.length; i++) {
            AssetInfo memory requiredAsset = requiredAssets[i];
            if (requiredAsset.assetAddress == UserOperationLib.NativeAsset) {
                require(address(_broker).balance >= requiredAsset.amount, "A5");
            } else {
                uint256 balance = IERC20(requiredAsset.assetAddress).balanceOf(address(_broker));
                require(balance >= requiredAsset.amount, "A6");
            }
        }
    }

    function handleOpsV2(UserOperation[] calldata _userOps, address _broker, bytes memory _brokerSig, IAggregatedSignature.ProofWithPubInput calldata _proofWithPubInput) external {
        uint256 startGas = gasleft();
        ISmartAccount broker = accountFactory.getSmartAccount(_broker);
        require(address(broker) != address(0), "CA");
        require(brokerStatus[_broker], "CB");
        // collect sig info
        IAggregatedSignature.SigInfo[] memory sigInfos = new IAggregatedSignature.SigInfo[](_userOps.length + 1);
        uint256 count = 0;
        bytes memory pubData;
        for (uint256 i = 0; i < _userOps.length; i++) {
            UserOperation calldata userOp = _userOps[i];
            bytes32 userOpHash = sha256(abi.encodePacked(getUserOpHashV2(userOp)));
            require(!kontosLightNode.isProofUsed(userOpHash), "EXEB");
            kontosLightNode.updateUsedProofByEntryPoint(userOpHash);
            if (count == 0) {
                pubData = abi.encodePacked(userOpHash);
            } else {
                pubData = abi.encodePacked(pubData, userOpHash);
            }
            sigInfos[count].pubKey = preValidateUserOp(broker, userOp);
            sigInfos[count].msgHash = userOpHash;
            sigInfos[count].signature = userOp.sigOrProof;
            count++;
        }
        sigInfos[count].pubKey = broker.pubKey();
        sigInfos[count].msgHash = sha256(abi.encodePacked(pubData, _broker));
        sigInfos[count].signature = _brokerSig;
        count++;

        // verify sigs first
        sigVerifier.verifyByZk(sigInfos, count, _proofWithPubInput);
        // collect fund from accounts and then execute ops
        for (uint256 i = 0; i < _userOps.length; i++) {
            UserOperation calldata userOp = _userOps[i];
            ExecuteOpData memory executeRes = _executeOpV2(userOp, broker);
            bytes32 userOpHash = getUserOpHashV2(userOp);
            ExecutionData memory returnValue = ExecutionData({
                opHash: userOpHash,
                executionRes: ExecutionRes({
                status: executeRes.status,
                accountAddr: executeRes.accountProxyAddress,
                executedAt: block.number,
                actualGasCost: executeRes.actualGasCost,
                revertReason: executeRes.revertRes}),
                paymentData: new PaymentData[](0),
                gasPayer: address(0),
                gasPrice: tx.gasprice
            });
            returnValue.gasPayer = _broker;
            emit OpExecution(returnValue);
        }
        uint256 usedGas = startGas - gasleft();
        AssetInfo memory compensateAsset = AssetInfo({
            assetAddress: UserOperationLib.NativeAsset,
            amount: tx.gasprice * (usedGas + 50000)
        });
        broker.prePay(msg.sender, compensateAsset);
    }

    function replaceAddress(bytes calldata data, address oldAddress, address newAddress) internal pure returns (bytes memory) {
        bytes memory result = new bytes(data.length);

        assembly {
            calldatacopy(add(result, 0x20), data.offset, data.length)

            let oldAddr := oldAddress
            let newAddr := newAddress
            let dataSize := mload(result)
            let end := add(dataSize, add(result, 0x20))

            for {let ptr := add(result, 0x20)} lt(ptr, end) {ptr := add(ptr, 0x1)} {
                if eq(mload(ptr), oldAddr) {
                    mstore(ptr, newAddr)
                }
            }
        }

        return result;
    }

    function _createOrUpdateOrGetAccount(UserOperation calldata _userOp) internal returns (ISmartAccount){
        bool hasAccount = accountFactory.hasAccount(_userOp.sender);
        if (hasAccount) {
            ISmartAccount account = accountFactory.getSmartAccount(_userOp.sender);
            if (_userOp.initCode.length != 0) {
                // update account
                uint256[2] memory pk = abi.decode(_userOp.initCode, (uint256[2]));
                account.updatePubKey(pk);
                emit AccountNewPubKey(_userOp.sender, address(account), pk);
            }
            return account;
        } else {
            address newAaAddr = accountFactory.createSmartAccount(_userOp.sender, _userOp.initCode);
            uint256[2] memory pk = abi.decode(_userOp.initCode, (uint256[2]));
            emit AccountNewPubKey(_userOp.sender, newAaAddr, pk);
            return ISmartAccount(newAaAddr);
        }
    }

    function _executeOp(bytes32 _opHash, UserOperation calldata _userOp, ISmartAccount payer) internal returns (ExecuteOpData memory) {
        // broker transfer required asset to smart account
        ISmartAccount account = _createOrUpdateOrGetAccount(_userOp);
        address accountProxy = address(account);
        // this action must succeed
        if (_userOp.requiredAssets.length > 0) {
            AssetInfo[] memory _requiredAssets = _userOp.requiredAssets;
            for (uint256 i = 0; i < _requiredAssets.length; i++) {
                AssetInfo memory asset = _requiredAssets[i];
                payer.prePay(accountProxy, asset);
            }
        }
        // help user call function
        uint256 actualGasCost = 0;
        if (_userOp.callData.length != 0) {
            bytes memory data = replaceAddress(_userOp.callData, _userOp.sender, address(account));
            uint256 initGas = gasleft();
            (bool success, bytes memory result) = address(account).call{gas: _userOp.callGasLimit}(data);
            actualGasCost = initGas - gasleft();
            // emit payments data
            _handlePayments(_userOp.sender, _opHash, _userOp.fundInfo, success);
            if (!success) {
                // return money back
                if (_userOp.requiredAssets.length > 0) {
                    AssetInfo[] memory _requiredAssets = _userOp.requiredAssets;
                    for (uint256 i = 0; i < _requiredAssets.length; i++) {
                        AssetInfo memory asset = _requiredAssets[i];
                        account.prePay(address(payer), asset);
                    }
                }
                return ExecuteOpData({status: UserOperationLib.OperationStatus.FailAtExecuteTx, accountProxyAddress: accountProxy, revertRes: result, actualGasCost: actualGasCost});
            }
        }
        return ExecuteOpData({status: UserOperationLib.OperationStatus.Success, accountProxyAddress: accountProxy, revertRes: "", actualGasCost: actualGasCost});
    }

    function _executeOpV2(UserOperation calldata _userOp, ISmartAccount payer) internal returns (ExecuteOpData memory) {
        // broker transfer required asset to smart account
        ISmartAccount account = _createOrUpdateOrGetAccount(_userOp);
        address accountProxy = address(account);
        // this action must succeed
        if (_userOp.requiredAssets.length > 0) {
            AssetInfo[] memory _requiredAssets = _userOp.requiredAssets;
            for (uint256 i = 0; i < _requiredAssets.length; i++) {
                AssetInfo memory asset = _requiredAssets[i];
                payer.prePay(accountProxy, asset);
            }
        }
        // help user call function
        uint256 actualGasCost = 0;
        if (_userOp.callData.length != 0) {
            bytes memory data = replaceAddress(_userOp.callData, _userOp.sender, address(account));
            uint256 initGas = gasleft();
            (bool success, bytes memory result) = address(account).call{gas: _userOp.callGasLimit}(data);
            actualGasCost = initGas - gasleft();
            if (!success) {
                // return money back
                if (_userOp.requiredAssets.length > 0) {
                    AssetInfo[] memory _requiredAssets = _userOp.requiredAssets;
                    for (uint256 i = 0; i < _requiredAssets.length; i++) {
                        AssetInfo memory asset = _requiredAssets[i];
                        account.prePay(address(payer), asset);
                    }
                }
                return ExecuteOpData({status: UserOperationLib.OperationStatus.FailAtExecuteTx, accountProxyAddress: accountProxy, revertRes: result, actualGasCost: actualGasCost});
            }
        }
        return ExecuteOpData({status: UserOperationLib.OperationStatus.Success, accountProxyAddress: accountProxy, revertRes: "", actualGasCost: actualGasCost});
    }

    event ProofTaskHandled(bytes32 _opHash, uint32 _proofType);

    event AccountNewPubKey(address _nameAddress, address _aaAccount, uint256[2] _pk);

    // Update Headers
    // Membership Proof
    function handleKontosProof(KontosProofHelper.AggregatedKontosProof calldata _proof) external {
        // verify proof data via light client
        kontosLightNode.verifyKontosProofAndUpdateHeaders(_proof);
        // decode proof task
        for (uint256 i = 0; i < _proof.lightHeaderWithProofsArr.length; i++) {
            KontosProofHelper.LightHeaderWithProofs memory lightHeaderWithProofs = _proof.lightHeaderWithProofsArr[i];
            for (uint256 j = 0; j < lightHeaderWithProofs.kontosStoragePairs.length; j++) {
                KontosProofHelper.KontosStoragePair memory kontosStoragePair = lightHeaderWithProofs.kontosStoragePairs[j];
                KontosProofHelper.ProofTask memory proofTask = KontosProofHelper.decodeProofTask(kontosStoragePair.storageValue);
                // handle proof task
                handleProofTask(msg.sender, proofTask);
            }
        }
    }

    struct Reward {
        address account;
        address assetAddress;
        uint256 amount;
    }

    event NotEnoughBalance(address _asset, uint256 _amount, uint256 _balance);

    function handleProofTask(address _caller, KontosProofHelper.ProofTask memory _proofTask) internal {
        if (_proofTask.proofType == uint32(KontosProofHelper.ProofType.ACCOUNT_UPDATE_PUB_KEY)) {
            KontosProofHelper.ProofAccountPubKey memory proofData = KontosProofHelper.decodeProofAccountPubKey(_proofTask.data);
            bool hasAccount = accountFactory.hasAccount(proofData.nameAddress);
            address aaAccount;
            if (hasAccount) {
                ISmartAccount account = accountFactory.getSmartAccount(proofData.nameAddress);
                aaAccount = address(account);
                account.updatePubKey{gas: _proofTask.callGasLimit}(proofData.pk);
            } else {
                aaAccount = accountFactory.createSmartAccount{gas: _proofTask.callGasLimit}(proofData.nameAddress, abi.encode(proofData.pk));
            }
            emit AccountNewPubKey(proofData.nameAddress, aaAccount, proofData.pk);
        } else if (_proofTask.proofType == uint32(KontosProofHelper.ProofType.REWARDS_DISTRIBUTION)) {
            KontosProofHelper.ProofRewardDistribution[] memory proofs = KontosProofHelper.decodeProofRewardDistributions(_proofTask.data);
            for (uint256 i = 0; i < proofs.length; i++) {
                KontosProofHelper.ProofRewardDistribution memory proof = proofs[i];
                ISmartAccount account = accountFactory.getSmartAccount(proof.payer);
                require(address(account) != address(0), "NKA");
                for (uint256 j = 0; j < proof.assets.length; j++) {
                    if (proof.assets[j].amount != 0) {
                        if (proof.assets[j].assetAddress == UserOperationLib.NativeAsset) {
                            if (address(account).balance < proof.assets[j].amount) {
                                revert("NEB");
                            }
                        } else {
                            uint256 balance = IERC20(proof.assets[j].assetAddress).balanceOf(address(account));
                            if (balance < proof.assets[j].amount) {
                                revert("NEB");
                            }
                        }
                        account.prePay(address(this), proof.assets[j]);
                    }
                }
                for (uint256 j = 0; j < proof.rewards.length; j++) {
                    KontosProofHelper.RewardRecord memory reward = proof.rewards[j];
                    address receiver = reward.receiver;
                    address accountReceiver = address(accountFactory.getSmartAccount(reward.receiver));
                    if (accountReceiver != address(0)) {
                        receiver = accountReceiver;
                    } else if (reward.receiver == address(0)) {
                        receiver = _caller;
                    }
                    for (uint256 k = 0; k < reward.assets.length; k++) {
                        distributeRewards(payable(receiver), reward.assets[k]);
                    }
                }
            }
        } else {
            revert("NVT");
        }
        emit ProofTaskHandled(_proofTask.opHash, _proofTask.proofType);
    }

    function distributeRewards(address payable _receiver, AssetInfo memory _asset) internal {
        // this means native transfer
        uint256 transferAmount = _asset.amount;
        if (transferAmount != 0) {
            if (_asset.assetAddress == UserOperationLib.NativeAsset) {
                (bool success,) = payable(_receiver).call{value: transferAmount, gas: type(uint256).max}("");
                require(success, "distributeRewards: fail");
            } else {
                transferAmount = _asset.amount;
                IERC20 token = IERC20(_asset.assetAddress);
                SafeERC20.safeTransfer(token, _receiver, transferAmount);
            }
        }
    }

    bool private initGenesisBrokerAccountOnce;

    function initGenesisBrokerAccount(address[] memory _genesisBrokers, bytes[] memory _initCodes) external returns (address[] memory){
        require(!initGenesisBrokerAccountOnce, "D");
        address[] memory res = new address[](_genesisBrokers.length);
        for (uint256 i = 0; i < _genesisBrokers.length; i++) {
            brokerStatus[_genesisBrokers[i]] = true;
            res[i] = accountFactory.createSmartAccount(_genesisBrokers[i], _initCodes[i]);
        }
        initGenesisBrokerAccountOnce = true;
        return res;
    }
}

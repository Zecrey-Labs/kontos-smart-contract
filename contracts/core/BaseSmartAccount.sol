// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ISmartAccount.sol";
import "../interfaces/IEntryPoint.sol";

abstract contract BaseSmartAccount is ISmartAccount {

    function nonce() external view virtual returns (uint64);

    function entryPoint() public view virtual returns (IEntryPoint);

    function _prePay(address _receiver, AssetInfo memory _asset) internal virtual {
        if (_asset.amount != 0) {
            bool success;
            if (_asset.assetAddress != UserOperationLib.NativeAsset) {
                // auto approve
                SafeERC20.safeTransfer(IERC20(_asset.assetAddress), _receiver, _asset.amount);
            } else {
                (success,) = payable(_receiver).call{value: _asset.amount, gas: type(uint256).max}("");
                require(success, "prePay: fail");
            }
        }
    }

    function prePay(address _receiver, AssetInfo memory _asset) external payable virtual {
        _requireFromEntryPoint();
        _prePay(_receiver, _asset);
    }

    /**
     * ensure the request comes from the known entrypoint.
     */
    function _requireFromEntryPoint() internal virtual view {
        require(msg.sender == address(entryPoint()), "account: not from EntryPoint");
    }

    function compensate(address _receiver, uint256 _fund) external payable virtual {
        _requireFromEntryPoint();
        (bool success,) = payable(_receiver).call{value: _fund}("");
        require(success, "account: pay fail");
    }

}

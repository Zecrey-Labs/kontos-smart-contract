// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BatchTransfer {

    struct TransferData {
        address receiver;
        address assetAddress;
        uint256 assetAmount;
    }

    function batchTransfer(TransferData[] memory _entities) external payable {
        for (uint256 i = 0; i < _entities.length; i++) {
            TransferData memory entity = _entities[i];
            if (entity.assetAmount != 0 && entity.receiver != address(0)) {
                if (entity.assetAddress != address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE)) {
                    // auto approve
                    SafeERC20.safeTransfer(IERC20(entity.assetAddress), entity.receiver, entity.assetAmount);
                } else {
                    bool success;
                    (success,) = payable(entity.receiver).call{value: entity.assetAmount, gas: type(uint256).max}("");
                    require(success, "prePay: fail");
                }
            }
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "../interfaces/IEntryPoint.sol";

abstract contract BaseEntryPoint is IEntryPoint {
    function getUserOpHash(UserOperation calldata _userOp) public view virtual returns (bytes32);

    function getUserOpHashV2(UserOperation calldata _userOp) public view virtual returns (bytes32);

    function preValidateUserOp(ISmartAccount _broker, UserOperation calldata _userOp) public view virtual returns (uint256[2] memory);

}

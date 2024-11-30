// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "../SmartAccount.sol";

interface ISmartAccountFactory {
    function createSmartAccount(address _addr, bytes calldata _initCode) external returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

interface IAuthProxy {
    function initialize(bytes calldata initializationParameters) external;

    function upgrade(bytes calldata params) external;

    function auth(bytes calldata _authInfo) external;
}

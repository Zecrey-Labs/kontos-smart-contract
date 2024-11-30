// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "../interfaces/ISmartAccountFactory.sol";
import "../interfaces/ISmartAccount.sol";


abstract contract BaseSmartAccountFactory is ISmartAccountFactory {

    function hasAccount(address _addr) public view virtual returns (bool);

    function getSmartAccount(address _addr) public view virtual returns (ISmartAccount);

    function nameAddress(string calldata _name) public pure virtual returns (address){
        return address(uint160(uint256(keccak256(abi.encode(_name)))));
    }
}

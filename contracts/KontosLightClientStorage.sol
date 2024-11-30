// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

contract KontosLightClientStorage {
    mapping(uint64 => bytes32) public kontosStorageSimHeaders;
    mapping(uint64 => bytes) public slotStorageHeaders;
    uint64 public tip;
    mapping(bytes32 => bool) internal provedStoragePair;
    bytes internal slot1;
    bytes internal slot2;
    bytes internal slot3;
}

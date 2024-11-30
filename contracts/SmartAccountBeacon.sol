// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SmartAccountBeacon is Ownable {
    UpgradeableBeacon immutable beacon;

    constructor(address _initTarget, address _owner) {
        beacon = new UpgradeableBeacon(_initTarget);
        require(_initTarget != address(0), "SAB0");
        transferOwnership(_owner);
    }

    function update(address _newTarget) public onlyOwner {
        require(_newTarget != address(0), "SAB1");
        beacon.upgradeTo(_newTarget);
    }

    function implementation() public view returns (address){
        return beacon.implementation();
    }

}

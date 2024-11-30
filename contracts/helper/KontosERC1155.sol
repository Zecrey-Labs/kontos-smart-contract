// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract KontosERC1155 is ERC1155 {
    constructor(string memory uri) ERC1155(uri){
    }

}

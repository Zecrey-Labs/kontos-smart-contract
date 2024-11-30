// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract KontosERC721 is ERC721 {
    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol){
    }

}

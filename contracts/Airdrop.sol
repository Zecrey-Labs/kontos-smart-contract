// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Airdrop is Ownable {

    bytes32 public root;
    IERC20 public token;
    mapping(address => bool) public claimed;

    constructor(address _owner, IERC20 _token) {
        _transferOwnership(_owner);
        token = _token;
    }

    function updateRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    function claim(uint256 _amount, bytes32[] memory _proof) external {
        require(!claimed[msg.sender], "C");
        bytes32 _leaf = keccak256(abi.encode(msg.sender, _amount));
        bool isValid = MerkleProof.verify(_proof, root, _leaf);
        require(isValid, "IVP");
        claimed[msg.sender] = true;
        SafeERC20.safeTransfer(IERC20(token), msg.sender, _amount);
    }
}

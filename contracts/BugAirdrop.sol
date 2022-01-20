//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDaoToken.sol";

contract BugAirdrop is Ownable {

    bytes32 public merkleRoot;
    uint256 public claimed;
    address public bugDaoToken;
    uint32  public round = 0;
    mapping(uint32 => mapping(address => bool)) isClaimed;

    event MerkleRootChanged(bytes32 merkleRoot);

    constructor(bytes32 root){
        merkleRoot = root;
    }

    function claimTokens(uint256 amount, uint256 deadline, bytes32[] calldata Proof) external {
        require(block.timestamp <= deadline, "BugDao: Too late.");
        require(!isClaimed[round][msg.sender],"BugDao: you have claimed.");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount, deadline));
        bool valid = MerkleProof.verify(Proof, merkleRoot, leaf);
        require(valid, "BugDao: Valid proof required.");
        isClaimed[round][msg.sender] = true;
        claimed += amount;
        IDaoToken(bugDaoToken).transferWithoutTax(msg.sender, amount);
    }
    
    function setBugToken(address _bugDaoToken) external onlyOwner {
        require(bugDaoToken == address(0), "only once");
        bugDaoToken = _bugDaoToken;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        round++;
        _setMerkleRoot(_merkleRoot);
    }

    function _setMerkleRoot(bytes32 _merkleRoot) internal{
        uint256 balance = IDaoToken(bugDaoToken).balanceOf(address(this));
        IDaoToken(bugDaoToken).transferWithoutTax(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, balance);
        IDaoToken(bugDaoToken).newAirdrop();
        merkleRoot = _merkleRoot;
        emit MerkleRootChanged(_merkleRoot);
    }
}

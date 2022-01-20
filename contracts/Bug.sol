//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./IDaoToken.sol";


contract Bug is IDaoToken, Ownable {
    using ECDSA for bytes32;

    string public constant override name = 'BugDAO';
    string public constant override symbol = 'BUG';
    uint8 public constant override decimals = 18;
    uint256 public override totalSupply;
    uint256 public initial = 4e27;
    uint256 public MaxSupply = 1e11 ether;
    uint   public counter = 0;
    address public airdrop;
    address public treasury = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    address public pair;

    bytes32 immutable public override DOMAIN_SEPARATOR;
 
    bytes32 public constant override PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public override nonces;

    event Transfer2Treasury(address from, address to, uint256 value);
    event SpendTreasury(uint256 value);
    event NewAirdrop(uint counter, uint256 value);
    event MerkleRootChanged(bytes32 merkleRoot);

     constructor(address _airdrop) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                block.chainid,
                address(this)
            )
        );
        airdrop = _airdrop;
        _mint(airdrop, 19_500_000_000 ether);
        _mint(msg.sender, 500_000_000 ether);
        _mint(address(this), 80_000_000_000 ether);
    }

    function _mint(address to, uint256 value) internal {
        require(totalSupply + value <=MaxSupply, "max supply limit");
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from] - value;
        uint256 treasuryValue = value * 1e17 / 1e18;
        uint256 transferValue = value - treasuryValue;
        balanceOf[treasury] += treasuryValue;
        balanceOf[to] += transferValue;
        emit Transfer2Treasury(from, treasury, treasuryValue);
        emit Transfer(from, to, transferValue);
    }

    function _transferWithoutTax(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function burn(uint256 value) external returns (bool) {
        _burn(msg.sender, value);
        return true;
    }

    function cleanTreasury() public onlyOwner {
        require(pair != address(0), "Should set pair first");
        uint256 balance = balanceOf[treasury];
        if (balance <= 0) {
            return;
        }
        // 80% to burn  and 20% reward to LP
        uint256 burnValue= balance * 8 * 1e17 /1e18;
        uint256 rewardValue = balance - burnValue;
        _burn(treasury, burnValue);
        _transferWithoutTax(treasury, pair, rewardValue);
        emit SpendTreasury(balance);
    }

    function newAirdrop() external override {
        require(msg.sender == airdrop, "only airdrop");
        uint256 balance = balanceOf[address(this)];
        require(balance > 0, "insufficient balance to create new airdrop");
        uint256 amount = initial * (95 ** counter) / (100 ** counter);
        if (balance < amount) {
            amount = balance;
        }
        _transferWithoutTax(address(this), airdrop, amount);
        counter += 1;
        emit NewAirdrop(counter, amount);
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferWithoutTax(address to, uint256 value) external override returns (bool) {
        require(msg.sender == airdrop, "Should called from timelock");
        _transferWithoutTax(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint256 value, uint deadline, uint8 v, bytes32 r, bytes32 s) external override {
        require(deadline >= block.timestamp, 'EXPIRED');

        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = digest.toEthSignedMessageHash().recover(v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    function setUniV2Pair(address _pair) public onlyOwner {
        require(pair==address(0), "Already set pair");
        pair = _pair;
    }
}

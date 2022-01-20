const { expect } = require('chai');
const chai = require('chai');
const { solidity } = require('ethereum-waffle');
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256');

chai.use(solidity);

describe('test airdrop', function () {

  const { constants, provider, BigNumber, utils } = ethers;

  const { AddressZero } = constants;
  const ETH = utils.parseEther('1');
  const Treasury = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";
  const Pair = "0x1111111111111111111111111111111111111111"
  const ZERO = BigNumber.from(0);
  const deadline = 1642760000;

  let BugDaoToken;
  let AirdropContract;

  let owner, bob, alice, bob_leaf, alice_leaf, leaves;
  let bug, airdrop;


  before(async function () {
      BugDaoToken =  await ethers.getContractFactory("DaoToken");
      AirdropContract =  await ethers.getContractFactory("Airdrop");
      [owner, airdrop, bob, alice] = await ethers.getSigners();
  });

  beforeEach(async function () {
      leaves = [
            ["0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC", "1020000000000000000000"],
            ["0x938E2bd645b03a4aFF49D6f764663d8746c7fcF5", "220000000000000000000"],
            ["0x60Ba51eE230B30Fc499D09C13112C36d36A1889a", "320000000000000000000"],
            ["0x91B24aCC646Ea48924ECf823E7Dd513373DE730f", "420000000000000000000"],
            ["0xA35eBAE339A3d03B6cAED1F5aEC8d43C372a88B4", "620000000000000000000"],
            ["0x23198D7dfB33DDF1a2259134df4e3A815A790554", "720000000000000000000"],
            ["0x55016bddfd2f078304843670B30A96D475E3FF7E", "820000000000000000000"],
            ["0x55016bddfd2f078304843670B30A96D475E3FF7E", "920000000000000000000"],
      ].map(x => keccak256(ethers.utils.solidityPack(["address", "uint256", "uint256"], [x[0], BigNumber.from(x[1]), deadline])));
      let tree = new MerkleTree(leaves, keccak256, { sort: true });
      let root = tree.getHexRoot();
      console.log(bob.address)
      console.log('root', root)
      airdrop = await AirdropContract.deploy(root)
      bug = await BugDaoToken.deploy(airdrop.address)
      await airdrop.setBugToken(bug.address)
      bob_leaf = keccak256(ethers.utils.solidityPack(["address", "uint256", "uint256"], [bob.address, BigNumber.from("1020000000000000000000"), deadline]));
      alice_leaf = keccak256(ethers.utils.solidityPack(["address", "uint256", "uint256"], [alice.address, BigNumber.from("1040000000000000000000"), deadline]));
  });

  describe('#airdrop', () => {

    it('claim should work correctly', async () => {
        let tree = new MerkleTree(leaves, keccak256, { sort: true });
        let proof = tree.getHexProof(bob_leaf);
        await airdrop.connect(bob).claimTokens(BigNumber.from("1020000000000000000000"), deadline, proof)
        let bob_amount = await bug.balanceOf(bob.address)
        expect(bob_amount.div(ETH).toString()).to.equal("1020")
        return

        await bug.connect(bob).transfer(alice.address, bob_amount);
        let alice_amount = await bug.balanceOf(alice.address)
        expect(alice_amount.div(ETH).toString()).to.equal("918")

        let treasury_amount = await bug.balanceOf(Treasury);
        expect(treasury_amount.div(ETH).toString()).to.equal("102")

        leaves = [
            [bob.address, "1020000000000000000000"],
            [alice.address, "1040000000000000000000"],
            ["0x60Ba51eE230B30Fc499D09C13112C36d36A1889a", "320000000000000000000"],
            ["0x91B24aCC646Ea48924ECf823E7Dd513373DE730f", "420000000000000000000"],
            ["0xA35eBAE339A3d03B6cAED1F5aEC8d43C372a88B4", "620000000000000000000"],

        ].map(x => keccak256(ethers.utils.solidityPack(["address", "uint256", "uint256"], [x[0], BigNumber.from(x[1]), deadline])));
        tree = new MerkleTree(leaves, keccak256, { sort: true });
        root = tree.getHexRoot();
        proof = tree.getHexProof(alice_leaf);
        await bug.setUniV2Pair(Pair)
        await airdrop.connect(owner).setMerkleRoot(root)
        await airdrop.connect(alice).claimTokens(BigNumber.from("1040000000000000000000"), deadline, proof)
        alice_amount = await bug.balanceOf(alice.address)
        expect(alice_amount.div(ETH).toString()).to.equal("1958")
    });
  }); 

});

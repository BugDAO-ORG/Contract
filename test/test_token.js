const { expect } = require('chai');
const chai = require('chai');
const { solidity } = require('ethereum-waffle');

chai.use(solidity);

describe('test token', function () {

  const { constants, provider, BigNumber, utils } = ethers;

  const { AddressZero } = constants;
  const ETH = utils.parseEther('1');
  const ZERO = BigNumber.from(0);

  let BugDaoToken;
  let owner, airdrop;

  let bug;
  

  before(async function () {
      BugDaoToken =  await ethers.getContractFactory("DaoToken");
      [owner, airdrop] = await ethers.getSigners();
  });

  beforeEach(async function () {
      bug = await BugDaoToken.deploy(airdrop.address)
  });

  it('should work correctly', async () => {
      const airdrop_amount = await bug.balanceOf(airdrop.address)
      const owner_amount = await bug.balanceOf(owner.address)
      const locked_amount = await bug.balanceOf(bug.address)
      expect(airdrop_amount.div(ETH).toString()).to.equal("195000000000")
      expect(owner_amount.div(ETH).toString()).to.equal("5000000000")
      expect(locked_amount.div(ETH).toString()).to.equal("800000000000")
  });
});

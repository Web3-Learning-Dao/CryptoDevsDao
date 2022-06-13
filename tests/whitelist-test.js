const { expect } = require('chai');
const { ethers, deployments, getNamedAccounts} = require('hardhat');
const keccak256 = require('keccak256');
const { isTypedArray } = require('util/types');
const { testArgs } = require('../utils/configs');
const { setupProof, contractsReady } = require('../utils/helpers');
const _args = testArgs();

describe("whitelist contract", function() {
    before(async function () {
        await setupProof(this);
    });

    beforeEach(async function () {
        await contractsReady(this)();
    });   

    it("add whitlist for address to the owner deploy!",async function(){
        await deployments.fixture(["Whitelist"]);
        const {tokenOwner,play1} = await getNamedAccounts();
        const Token = await ethers.getContract("Whitelist");
        const whitelistData = await Token.getALLWhiteListData();
        console.log("whitelistData ==> ",whitelistData);
        await Token.addAddressToWhitelist(play1);
        const whitelistData2 = await Token.getALLWhiteListData();
        console.log("whitelistData2 ==> ",whitelistData2);
        const num = await Token.getALLWhiteListNum();
        console.log("ALLWhiteListNum==>",num);
        expect(num).to.equal(1);
        expect(whitelistData2[0]).to.equal(play1);
    });

    it('add whitelist for merkleTreeRoot', async function () {
      await deployments.fixture(["Whitelist"]);
      const {tokenOwner,play1} = await getNamedAccounts();
      const Token = await ethers.getContract("Whitelist");
      await Token.updateWhitelist(this.rootHash);
      const checkWhitelistReturn = await Token.connect(await ethers.getSigner(this.accounts[0])).checkMerkleTreeRootForWhitelist(this.proofs[1]);
      expect(checkWhitelistReturn).to.equal(true);

    });

    describe('#updateWhitelist for merkleTree', function () {
        it('Should not updated by invalid account', async function () {
          await expect(
            this.Whitelist
              .connect(await ethers.getSigner(this.accounts[1]))
              .updateWhitelist(this.rootHash)
          ).to.be.revertedWith('NotInviter()');
          await this.Whitelist.connect(await ethers.getSigner(this.ownerAddress)).updateWhitelist(this.rootHash);
          const checkWhitelistReturn = await this.Whitelist.connect(await ethers.getSigner(this.accounts[0])).checkMerkleTreeRootForWhitelist(this.proofs[1]);
          expect(checkWhitelistReturn).to.equal(true);
          const checkWhitelistReturn1 = await this.Whitelist.connect(await ethers.getSigner(this.ownerAddress)).checkMerkleTreeRootForWhitelist(this.proofs[0]);
          expect(checkWhitelistReturn1).to.equal(true);
        });
      });
});

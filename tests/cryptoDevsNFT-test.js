const { expect } = require('chai');
const { ethers, deployments, getNamedAccounts} = require('hardhat');
const keccak256 = require('keccak256');
const { isTypedArray } = require('util/types');
const { testArgs } = require('../utils/configs');
const { setupProof, contractsReady } = require('../utils/helpers');
const _args = testArgs();
const zeroAddres = ethers.constants.AddressZero;

describe('CryptoDevsNFT TEST', function () {    
    before(async function () {
        await setupProof(this);
    });
    
    beforeEach(async function () {
        await contractsReady(this)();
    });

    describe('#whitelist mint', function () {
        it('Should able to mint NFT for account in whitelist', async function () {
          await this.Whitelist.connect(await ethers.getSigner(this.ownerAddress)).updateWhitelist(this.rootHash);
          await expect(this.CryptoDevsNFT.connect(await ethers.getSigner(this.ownerAddress)).whiteListeMint(this.Whitelist.address,this.proofs[0]))
            .to.changeTokenBalance(this.CryptoDevsNFT, this.ownerAddress, 1)
            .to.emit(this.CryptoDevsNFT, 'Transfer')
            .withArgs(zeroAddres, this.ownerAddress, 0);
        });
    
        it('Should not able to mint NFT for an account more than once', async function () {
          await this.Whitelist.connect(await ethers.getSigner(this.ownerAddress)).updateWhitelist(this.rootHash);
          await this.CryptoDevsNFT.connect(await ethers.getSigner(this.ownerAddress)).whiteListeMint(this.Whitelist.address,this.proofs[0]);
    
          await expect(this.CryptoDevsNFT.connect(await ethers.getSigner(this.ownerAddress)).whiteListeMint(this.Whitelist.address,this.proofs[0])).to.be.revertedWith(
            'MembershipAlreadyClaimed()'
          );
        });
    
        it('Should not able to mint NFT for account in whitelist with badProof', async function () {
          await this.Whitelist.connect(await ethers.getSigner(this.ownerAddress)).updateWhitelist(this.rootHash);
    
          await expect(this.CryptoDevsNFT.connect(await ethers.getSigner(this.ownerAddress)).whiteListeMint(this.Whitelist.address,this.badProof)).to.be.revertedWith('NOtWhitelists()');
        });
    
        it('Should not able to mint NFT for account not in whitelist', async function () {
          await this.Whitelist.connect(await ethers.getSigner(this.ownerAddress)).updateWhitelist(this.rootHash);
    
          await expect(
            this.CryptoDevsNFT.connect(await ethers.getSigner(this.accounts[4])).whiteListeMint(this.Whitelist.address,this.badProof)
          ).to.be.revertedWith('NOtWhitelists()');
        });
    });

    describe('#public Mint', function () {
        it('Should able to mint NFT for public with not startPresale', async function (){
            expect(await this.CryptoDevsNFT.publicMint()).to.equal('Presale has not ended yet');
        });

        it('Should able to mint NFT for public with  startPresale',async function(){
            const preastime = 1000;
            await this.CryptoDevsNFT.setPresaleTime(preastime);
            await this.CryptoDevsNFT.startPresale();
            expect(await this.CryptoDevsNFT.publicMint()).to.equal(1);

        });

    });

    describe('invest Mint',function(){

    });

});

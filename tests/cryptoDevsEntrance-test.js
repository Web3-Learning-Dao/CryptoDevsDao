const { expect } = require('chai');
const { ethers, deployments } = require('hardhat');
const { setupProof, contractsReady } = require('../utils/helpers');

describe('CryptoEntrance test', function () {
  before(async function () {
    await setupProof(this);
  });

  beforeEach(async function () {
    await contractsReady(this, false)();
  });

  describe('deployment check', function () {
    it('Should created with related contracts', async function () {
      expect(await this.CryptoDevsEntrance.cryptoDevsNFT()).to.equal(await this.CryptoDevsNFT.address);
      expect(await this.CryptoDevsEntrance.cryptoDevsToken()).to.equal(await this.CryptoDevsToken.address);
      expect(await this.CryptoDevsEntrance.governorNFT()).to.equal(await this.GovernorNFT.address);
      expect(await this.CryptoDevsEntrance.governorToken()).to.equal(await this.GovernorToken.address);
      expect(await this.CryptoDevsEntrance.whitelist()).to.equal(await this.Whitelist.address);
    });
  });
});

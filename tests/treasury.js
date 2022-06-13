const { expect } = require('chai');
const { ethers, deployments } = require('hardhat');
const { setupProof, contractsReady } = require('../utils/helpers');

describe('Treasury', function () {
  before(async function () {
    await setupProof(this);
  });

  beforeEach(async function () {
    await contractsReady(this, true)();
  });

  describe('deployment check', function () {
    it('Should created with related contracts', async function () {
      expect(await this.treasury.cryptoDevsTokenAddress()).to.equal(await this.CryptoDevsEntrance.cryptoDevsToken());
      expect(await this.treasury.cryptoDevsNFTAddress()).to.equal(this.CryptoDevsNFT.address);
    });
  });
});

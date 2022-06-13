const keccak256 = require('keccak256');
const { MerkleTree } = require('merkletreejs');
const { deployments, ethers } = require('hardhat');

module.exports.setupProof = async function (context, _index = 4) {
    const { deployer } = await getNamedAccounts();
    const accounts = await getUnnamedAccounts();
  
    const whitelistAddresses = [deployer].concat(accounts.filter((_, idx) => idx < _index));
    //console.log("whitelistAddresses:",whitelistAddresses);
    const leafNodes = whitelistAddresses.map((adr) => keccak256(adr));
    const merkleTree = new MerkleTree(leafNodes, keccak256, {
      sortPairs: true,
    });
   // console.log("merkleTree:",merkleTree);
    
    const deps = {
      rootHash: merkleTree.getHexRoot(),
      proofs: whitelistAddresses.map((addr) => merkleTree.getHexProof(keccak256(addr))),
      badProof: merkleTree.getHexProof(keccak256(accounts[_index])),
      whitelistAddresses,
      whitelistAccounts: await Promise.all(whitelistAddresses.map((v) => ethers.getSigner(v))),
      accounts,
      owner: await ethers.getSigner(deployer),
      ownerAddress: deployer,
    };
  
    if (context && typeof context === 'object') {
      Object.keys(deps).forEach((key) => (context[key] = deps[key]));
    }
  
    return deps;
};

module.exports.contractsReady = function (context, instantMint = false) {
    return deployments.createFixture(async ({ deployments, ethers }, options) => {
      await deployments.fixture();
  
      const Governor = await ethers.getContractFactory('TreasuryGovernor');
      const Treasury = await ethers.getContractFactory('Treasury');
      const CryptoDevsToken = await ethers.getContractFactory('CryptoDevsToken');
      const CryptoDevsNFT = await ethers.getContractFactory('CryptoDevsNFT');
      const Whitelist = await ethers.getContractFactory("Whitelist");
      const CryptoDevsEntrance = await ethers.getContract('CryptoDevsEntrance');

      if (instantMint) {
        await CryptoDevsEntrance.updateWhitelist(context.rootHash);
        await CryptoDevsEntrance.setupGovernor();
  
        // Do NOT use `context.whitelistAccounts.forEach` to avoid a block number change
        await Promise.all(
          context.whitelistAccounts.map((account, idx) => {
            return Promise.all([
                CryptoDevsEntrance.connect(account).mint(context.proofs[idx]),
                CryptoDevsEntrance.connect(account).delegate(context.whitelistAddresses[idx]),
            ]);
          })
        );
      }
  
      // Create a test merkle tree
      const deps = {
        CryptoDevsEntrance,
        Whitelist: Whitelist.attach(await CryptoDevsEntrance.whitelist()),
        CryptoDevsNFT: CryptoDevsNFT.attach(await CryptoDevsEntrance.cryptoDevsNFT()),
        GovernorNFT: Governor.attach(await CryptoDevsEntrance.governorNFT()),
        Treasury: Treasury.attach(await CryptoDevsEntrance.treasury()),
        GovernorToken: Governor.attach(await CryptoDevsEntrance.governorToken()),
        CryptoDevsToken: CryptoDevsToken.attach(await CryptoDevsEntrance.cryptoDevsToken()),
      };
      // console.info("CryptoDevsEntrance address [%s] \
      //               Whitelist address [%s] \
      //               cryptoDevsNFT address [%s] \
      //               governorNFT address [%s] \
      //               treasury address [%s] \
      //               GovernorToken address [%s] \
      //               cryptoDevsToken address [%s]",
      //               CryptoDevsEntrance.address,Whitelist.address,CryptoDevsNFT.address,GovernorNFT.address,
      //               Treasury.address,GovernorToken.address,CryptoDevsToken.address);
 
      console.info("deps [%s]",deps);
  
      if (context && typeof context === 'object') {
        Object.keys(deps).forEach((key) => (context[key] = deps[key]));
      }
  
      return deps;
    });
};

module.exports.findEvent = async function (fn, eventName) {
    const tx = await fn;
    const recipe = await tx.wait();
    return recipe.events.find((e) => e.event === eventName).args;
};


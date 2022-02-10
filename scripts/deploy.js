const { WHITELIST_CONTRACT_ADDRESS, METADATA_URL } = require("../hardhat-tutorial/constants");

const main = async () => {
   // Address of the whitelist contract that you deployed in the previous module
   const whitelistContract = WHITELIST_CONTRACT_ADDRESS;
   // URL from where we can extract the metadata for a Crypto Dev NFT
   const metadataURL = METADATA_URL;

  const nftContractFactory = await hre.ethers.getContractFactory("MyEpicNFT");
  const nftContract = await nftContractFactory.deploy(
    metadataURL,
    whitelistContract
  );

  await nftContract.deployed();

  console.log("Contract deployed to:", nftContract.address);


   // Call the function.
   let txn = await nftContract.makeAnEpicNFT();
   // Wait for it to be mined.
   await txn.wait();
   
  };
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.error(error);
      process.exit(1);
    }
  };
  
  runMain();
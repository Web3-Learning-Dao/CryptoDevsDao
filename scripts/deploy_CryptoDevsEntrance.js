const { WHITELIST_CONTRACT_ADDRESS, METADATA_URL } = require("../hardhat-tutorial/constants");
const { testArgs } = require('../utils/configs');

const main = async () => {

  const { deploy } = sdeployments;
  const { deployer } = await getNamedAccounts();

  await deploy('Membership', {
    from: deployer,
    args: testArgs(),
    log: true,
  });
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
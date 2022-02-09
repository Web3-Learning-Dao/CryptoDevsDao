const main = async () => {
    //获取两个随机地址
    //const [owner,randomPerson] = await hre.ethers.getSigners();
    //编译waveportal 合约文件
    const waveContractFactory = await hre.ethers.getContractFactory('Whitelist');
    //创建本地以太坊网络,给合约0.1eth
    const waveContract = await waveContractFactory.deploy(100,{value: hre.ethers.utils.parseEther("0.1"),});
    //等待合约部署到区块链
    await waveContract.deployed();
    // waveContract.address 部署以太网络地址
    console.log("Contract deployed to:", waveContract.address);

    //调用合约业务代码
    // let waveCont;
    // waveCont = await waveContract.getTotalWave();
    // let waveTxn = await waveContract.wave();
    // await waveTxn.wait();
    // waveCount = await waveContract.getTotalWave();

    // waveTxn = await waveContract.connect(randomPerson).wave();
    // await waveTxn.wait;
    // waveCount = await waveContract.getTotalWave();

    /*
    * Get Contract balance 获取合同余额
    */
    let contractBalance = await hre.ethers.provider.getBalance(
      waveContract.address
    );
    console.log(
      "Contract balance:",
      hre.ethers.utils.formatEther(contractBalance)
    );

    /**
     * Let's send a few waves!
     */
    // //1。/发送一条消息
    // let waveTxn = await waveContract.wave("A message 11111!");
    // await waveTxn.wait(); // Wait for the transaction to be mined
    // //2.获取一个地址发送一条消息
    // const [_, randomPerson] = await hre.ethers.getSigners();
    // waveTxn = await waveContract.connect(randomPerson).wave("Another message 1111!");
    // await waveTxn.wait(); // Wait for the transaction to be mined

    // waveTxn = await waveContract.connect(randomPerson).wave("Another message 2222!");
    // await waveTxn.wait(); // Wait for the transaction to be mined

    // //3.获取消息队列总数
    // let allWaves = await waveContract.getAllWaves();
    // //console.log(allWaves);
    // //监听事件
    // //waveContract.NewWave();
    // contractBalance = await hre.ethers.provider.getBalance(
    //   waveContract.address
    // );
    // console.log(
    //   "Contract balance:",
    //   hre.ethers.utils.formatEther(contractBalance)
    // );
  };
  
  const runMain = async () => {
    try {
      await main();
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
  
  runMain();
import "@nomiclabs/hardhat-ethers";
import { task } from "hardhat/config";
task("create-pair1", "Creates a new pair WBNB/fUSD")
  //.addParam("wbnb", "WrappedBNB Address")
  //.addParam("fUSD", "fUSD Address")
  //.addParam("uniFactory", "UniswapV2 Factory")
  .setAction(async (taskArgs, hre) => {
    const wbnbAddress = taskArgs.wbnb || process.env.WBNB_ADDRESS;
    const fUSDAddress = taskArgs.fUSD || process.env.FUSD_ADDRESS;
    const uniFactoryAddress =
      taskArgs.uniFactory || process.env.UNISWAPV2_FACTORY;

    console.log(
      `Creating UniswapV2Pair with WBNB@${wbnbAddress} and FUSD@${fUSDAddress} on UniswapV2Factory ${uniFactoryAddress} via network ${hre.network.name}`,
    );
    // Get signer information
    const accounts = await hre.ethers.getSigners();
    const signer = accounts[0];
    const uniFactory = await hre.ethers.getContractFactory(
      "UniswapV2Factory",
      signer,
    );
    const uniFactoryContract = new hre.ethers.Contract(
      uniFactoryAddress,
      uniFactory.interface,
      signer,
    );
    const txHash = await uniFactoryContract.createPair(
      wbnbAddress,
      fUSDAddress,
    );
    console.log(`New pair created with transaction: ${txHash.hash}`);
  });

import hre, { ethers } from "hardhat";
import uniV2Token from "../../deploy/UniswapV2Token";

async function main() {
  const wbnbAddress = "0xb532F8a65F8A86e30752B49647b5aDAF691989b0";
  const fUSDAddress = "0x1767Df317B12a235774B88184DBa80864B457478";
  const zUSDAddress = "0x76A8AA8276246E761Cc03C4c2C6C6D8Bb33f35DF";
  const uniRouterAddress = "0xF67702Ee0E53dB21402ed2d1F6271493F2922d72";
  const uniFactoryAddress = "0xea96F9004051cB3E04282B10CF58603c2a1b5a55";
  const uinswapV2Token = "0x35a7B95d45E4fb81A865F0724a40D5ffC6D9066b";
  const wallet = await hre.ethers.getSigners();
  const uniFactoryContract = await hre.ethers.getContractAt(
    "UniswapV2Factory",
    uniFactoryAddress,
  );

  //const pair = await uniFactoryContract.createPair(fUSDAddress, uinswapV2Token);
  //console.log("Trx hash:", pair.hash);
  const pairCount = await uniFactoryContract.allPairsLength();
  console.log("All pairs length:", pairCount);
  const uniRouterContract = await hre.ethers.getContractAt(
    "UniswapV2Router",
    uniRouterAddress,
  );
  const uniV2TokenContract = await hre.ethers.getContractAt(
    "FUSD2Implimentation",
    fUSDAddress,
  );
  await uniV2TokenContract.approve(uniRouterAddress, ethers.MaxUint256);
  const txHash = await uniRouterContract.addLiquidity(
    uinswapV2Token,
    fUSDAddress,
    10000000,
    100000,
    1,
    1,
    wallet[0].address,
    ethers.MaxUint256,
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

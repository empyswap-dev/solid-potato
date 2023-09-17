import hre from "hardhat";

async function main() {
  const wbnbAddress = "0x73511669fd4dE447feD18BB79bAFeAC93aB7F31f";
  const fUSDAddress = "0x8464135c8F25Da09e49BC8782676a84730C318bC";
  const zUSDAddress = "0xbdEd0D2bf404bdcBa897a74E6657f1f12e5C6fb6";
  const uniRouterAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
  const uniFactoryAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
  const wallet = await hre.ethers.getSigners();
  const uniFactoryContract = await hre.ethers.getContractAt(
    "UniswapV2Factory",
    uniFactoryAddress,
  );

  const pair = await uniFactoryContract.createPair(wbnbAddress, fUSDAddress);
  console.log("Trx hash:", pair.hash);
  const pairCount = await uniFactoryContract.allPairsLength();
  console.log("All pairs length:", pairCount);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

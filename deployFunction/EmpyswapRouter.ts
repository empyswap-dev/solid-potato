import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const router: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  getChainId,
  run,
  ethers,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;
  const { wallet } = await getNamedAccounts();
  const chainId = parseInt(await getChainId());
  const factory = await ethers.getContract("UniswapV2Factory");
  const factoryAddress = await factory.getAddress();
  const wbnb = await ethers.getContract("WrappedBNB");
  const wbnbAddress = await wbnb.getAddress();
  const tx = await deploy("UniswapV2Router", {
    from: wallet,
    args: [factoryAddress, wbnbAddress],
    log: true,
    deterministicDeployment: false,
  });
  if (tx.newlyDeployed) {
    console.log(`with args ${factoryAddress} and ${wbnbAddress}`);
  }
  if (!tx.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: tx.address,
      constructorArguments: [factoryAddress, wbnbAddress],
    });
  }
};

router.tags = ["UniswapV2Router", "AMM"];

router.dependencies = ["UniswapV2Factory", "wbnb"];

export default router;

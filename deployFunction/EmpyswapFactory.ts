import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const factory: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  getChainId,
  run,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;
  const chainId = parseInt(await getChainId());
  const { wallet, feeTo } = await getNamedAccounts();
  const tx = await deploy("UniswapV2Factory", {
    from: wallet,
    args: [feeTo],
    log: true,
    deterministicDeployment: false,
  });
  if (tx.newlyDeployed) console.log(`with args ${feeTo}`);
  if (!tx.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: tx.address,
      constructorArguments: [feeTo],
    });
  }
};

factory.tags = ["UniswapV2Factory", "AMM"];

export default factory;

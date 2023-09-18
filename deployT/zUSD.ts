import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const zUSD: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  getChainId,
  run,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;
  const chainId = parseInt(await getChainId());
  const { derex } = await getNamedAccounts();
  const token = await deploy("ZetherUSDImplementation", {
    from: derex,
    args: [],
    log: true,
    deterministicDeployment: false,
  });
  if (!token.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: token.address,
      constructorArguments: [],
    });
  }
};

zUSD.tags = ["zUSD", "Fiat"];

zUSD.dependencies = ["UniswapV2Router", "fUSD"];

export default zUSD;

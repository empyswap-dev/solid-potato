import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const fUSD: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  run,
  getChainId,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;
  const chainId = parseInt(await getChainId());
  const { alice } = await getNamedAccounts();
  const token = await deploy("FUSD2Implimentation", {
    from: alice,
    args: [],
    log: true,
    deterministicDeployment: false,
  });
  if (token.newlyDeployed) console.log(`with no args`);
  if (!token.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: token.address,
      constructorArguments: [],
    });
  }
};

fUSD.tags = ["fUSD", "Fiat"];

fUSD.dependencies = ["UniswapV2Router"];

export default fUSD;

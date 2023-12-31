import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { mkRoot } from "../src/test/shared/merkle-tree";

const wbnb: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  getChainId,
  run,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;
  const phrase =
    "amount pottery mammal state foster problem connect salad north midnight carbon rhythm";
  const root = await mkRoot(phrase);
  const chainId = parseInt(await getChainId());
  const { wbnbDeployer } = await getNamedAccounts();
  const tx = await deploy("WrappedBNB", {
    from: wbnbDeployer,
    args: [root.ROOT],
    log: true,
    deterministicDeployment: false,
  });
  if (!tx.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: tx.address,
      constructorArguments: [root.ROOT],
    });
  }
};

wbnb.tags = ["wbnb", "MockToken"];

export default wbnb;

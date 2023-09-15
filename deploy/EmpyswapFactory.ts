import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

const factory: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer, feeTo } = await getNamedAccounts();
  await deploy("EmpyswapFactory", {
    from: deployer,
    args: [feeTo],
    log: true,
    deterministicDeployment: false,
  });
};

factory.tags = ["EmpyswapFactory", "AMM"];

export default factory;

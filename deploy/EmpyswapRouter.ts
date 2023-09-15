import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";

const router: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  getChainId,
  ethers,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;

  const { deployer } = await getNamedAccounts();

  const chainId = parseInt(await getChainId());

  const factory = await ethers.getContract("EmpyswapFactory");
  const wbnbAddress = "0x4200000000000000000000000000000000000006";

  await deploy("EmpyswapRouter", {
    from: deployer,
    args: [await factory.getAddress(), wbnbAddress],
    log: true,
    deterministicDeployment: false,
  });
};

router.tags = ["EmpyswapRouter", "AMM"];

router.dependencies = ["EmpyswapFactory", "MockToken"];

export default router;

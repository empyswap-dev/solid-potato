import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { ethers } from "hardhat";

const zUSD: DeployFunction = async function ({
    getNamedAccounts,
    deployments,
}: HardhatRuntimeEnvironment) {
    const { deploy } = deployments;

    const { carol } = await getNamedAccounts();
    const token = await deploy("ZetherUSDImplementation", {
        from: carol,
        args: [],
        log: true,
        deterministicDeployment: false,
    });
};

zUSD.tags = ["zUSD", "Fiat"];

zUSD.dependencies = ["EmpyswapRouter", "eUSD"];

export default zUSD;

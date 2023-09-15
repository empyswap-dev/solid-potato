import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { ethers } from "hardhat";

const eUSD: DeployFunction = async function ({
    getNamedAccounts,
    deployments,
}: HardhatRuntimeEnvironment) {
    const { deploy } = deployments;

    const { dev, alice, bob } = await getNamedAccounts();
    const token = await deploy("EnterpriseFiatImplementation", {
        from: dev,
        args: [alice, bob, dev],
        log: true,
        deterministicDeployment: false,
    });
};

eUSD.tags = ["eUSD", "Fiat"];

eUSD.dependencies = ["EmpyswapRouter"];

export default eUSD;

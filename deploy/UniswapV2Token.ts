import { ethers } from "hardhat";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import {
  expandTo15Decimals,
  expandTo18Decimals,
  getDayBySecond,
} from "../src/test/shared/utilities";

const uniV2Token: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  getChainId,
  run,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;
  const name = "UniswapV2 Token";
  const symbol = "UVT";
  const amount = expandTo18Decimals(1000);
  const block = await ethers.provider.getBlock("latest");
  console.log(block?.number);
  const { wallet, feeTo } = await getNamedAccounts();
  const chainId = parseInt(await getChainId());
  const txRewardToken = await deploy("UniswapV2Token", {
    from: wallet,
    args: [name, symbol, amount],
    log: true,
    deterministicDeployment: false,
  });
  if (!txRewardToken.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: txRewardToken.address,
      constructorArguments: [name, symbol, amount],
    });
  }
  const uniV2 = await ethers.getContractAt(
    "UniswapV2Token",
    txRewardToken.address,
  );
  //await uniV2.transfer(feeTo, expandTo18Decimals(100));
  const startBlock =
    BigInt(await ethers.provider.getBlockNumber()) + getDayBySecond(1);
  const endBlock = startBlock + getDayBySecond(7);
  const rewardsPerBlock = expandTo15Decimals(1);
  const txMasterChef = await deploy("MasterChef", {
    from: wallet,
    args: [txRewardToken.address, rewardsPerBlock, startBlock, endBlock],
    log: true,
    deterministicDeployment: false,
  });
  if (!txMasterChef.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: txMasterChef.address,
      constructorArguments: [
        txRewardToken.address,
        rewardsPerBlock,
        startBlock,
        endBlock,
      ],
    });
  }
  const uniV2Owner = await uniV2.owner();
  if (
    txMasterChef.newlyDeployed &&
    uniV2Owner !== txMasterChef.address &&
    uniV2Owner === wallet
  ) {
    await uniV2.transferOwnership(txMasterChef.address);
  }
};

uniV2Token.tags = ["UniswapV2Token", "MockToken"];

uniV2Token.dependencies = ["Fiat"];

export default uniV2Token;

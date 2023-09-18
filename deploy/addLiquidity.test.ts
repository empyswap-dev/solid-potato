import { DeployFunction } from "hardhat-deploy/dist/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { mkRoot } from "../src/test/shared/merkle-tree";
import {
  expandTo15Decimals,
  expandTo18Decimals,
  getDayBySecond,
} from "../src/test/shared/utilities";
import { parseEther } from "ethers";

const wbnb: DeployFunction = async function ({
  getNamedAccounts,
  deployments,
  getChainId,
  ethers,
  run,
}: HardhatRuntimeEnvironment) {
  const { deploy } = deployments;
  const phrase =
    "amount pottery mammal state foster problem connect salad north midnight carbon rhythm";
  const root = await mkRoot(phrase);
  const name = "UniswapV2 Reward Token";
  const symbol = "UVRT";
  const amount = expandTo18Decimals(7777);
  const chainId = parseInt(await getChainId());
  const { wallet, alice, bobby, carol, derex, feeTo, wbnbDeployer } =
    await getNamedAccounts();
  // deploy WrappedBNB
  const txWrappedBNB = await deploy("WrappedBNB", {
    from: wbnbDeployer,
    args: [root.ROOT],
    log: true,
    deterministicDeployment: false,
  });
  if (txWrappedBNB.newlyDeployed) console.log(`with args ${root.ROOT}`);
  if (!txWrappedBNB.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: txWrappedBNB.address,
      constructorArguments: [root.ROOT],
    });
  }
  // deploy FUSD2Implimentation
  const txFUSD = await deploy("FUSD2Implimentation", {
    from: alice,
    args: [],
    log: true,
    deterministicDeployment: false,
  });
  if (txFUSD.newlyDeployed) console.log(`with no args`);
  if (!txFUSD.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: txFUSD.address,
      constructorArguments: [],
    });
  }
  const fusdToken = await ethers.getContractAt(
    "FUSD2Implimentation",
    txFUSD.address,
    await ethers.getSigner(alice),
  );
  //deploy ZetherUSDImplementation
  const txZUSD = await deploy("ZetherUSDImplementation", {
    from: derex,
    args: [],
    log: true,
    deterministicDeployment: false,
  });
  if (txZUSD.newlyDeployed) console.log(`with no args`);
  if (!txZUSD.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: txZUSD.address,
      constructorArguments: [],
    });
  }
  const zusdToken = await ethers.getContractAt(
    "ZetherUSDImplementation",
    txZUSD.address,
    await ethers.getSigner(derex),
  );
  console.log("Minting ZUSD to SupplyController:...");
  await zusdToken.increaseSupply(expandTo18Decimals(100000000));
  console.log("Total ZUSD supply is:", await zusdToken.balanceOf(derex));
  // deploy UniswapV2Factory
  const txUniswapV2Factory = await deploy("UniswapV2Factory", {
    from: wallet,
    args: [feeTo],
    log: true,
    deterministicDeployment: false,
  });
  if (txUniswapV2Factory.newlyDeployed) console.log(`with args ${feeTo}`);
  if (!txUniswapV2Factory.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: txUniswapV2Factory.address,
      constructorArguments: [feeTo],
    });
  }
  const uniswapV2Factory = await ethers.getContractAt(
    "UniswapV2Factory",
    txUniswapV2Factory.address,
    await ethers.getSigner(wallet),
  );
  // create WBNB/FUSD pair
  await uniswapV2Factory.createPair(txWrappedBNB.address, txFUSD.address);
  const pairWBNB2FUSD = await uniswapV2Factory.getPair(
    txWrappedBNB.address,
    txFUSD.address,
  );
  console.log("Pair WBNB/FUSD created at:", `${pairWBNB2FUSD}`);
  let pairs = await ethers.getContractAt("UniswapV2Pair", pairWBNB2FUSD);
  // create WBNB/ZUSD pair
  await uniswapV2Factory.createPair(txWrappedBNB.address, txZUSD.address);
  const pairZUSD2WBNB = await uniswapV2Factory.getPair(
    txWrappedBNB.address,
    txZUSD.address,
  );
  console.log("Pair WBNB/ZUSD created at:", `${pairZUSD2WBNB}`);
  // create stable poool
  await uniswapV2Factory.createPair(txZUSD.address, txFUSD.address);
  const pairFUSD2ZUSD = await uniswapV2Factory.getPair(
    txZUSD.address,
    txFUSD.address,
  );
  console.log("Pair ZUSD/FUSD created at:", `${pairFUSD2ZUSD}`);
  // deploy UniswapV2Router
  const txUniswapV2Router = await deploy("UniswapV2Router", {
    from: wallet,
    args: [txUniswapV2Factory.address, txWrappedBNB.address],
    log: true,
    deterministicDeployment: false,
  });
  if (txUniswapV2Router.newlyDeployed) {
    console.log(
      `with args ${txUniswapV2Factory.address} and ${txWrappedBNB.address}`,
    );
  }
  if (!txUniswapV2Router.newlyDeployed && chainId !== 31337) {
    await run("verify:verify", {
      address: txUniswapV2Router.address,
      constructorArguments: [txUniswapV2Factory.address, txWrappedBNB.address],
    });
  }
  let uniswapV2Router = await ethers.getContractAt(
    "UniswapV2Router",
    txUniswapV2Router.address,
    await ethers.getSigner(alice),
  );
  // addLiquidityWithStable WBNB/FUSD
  await fusdToken.approve(txUniswapV2Router.address, ethers.MaxUint256);
  console.log("Begining add liquidity...");
  await uniswapV2Router.addLiquidityETH(
    txFUSD.address,
    expandTo18Decimals(1868),
    0,
    0,
    alice,
    ethers.MaxInt256,
    { value: expandTo18Decimals(1) },
  );
  await zusdToken.unpause();
  await zusdToken.approve(txUniswapV2Router.address, ethers.MaxUint256);
  await fusdToken.transfer(derex, expandTo18Decimals(100000));
  await fusdToken
    .connect(await ethers.getSigner(derex))
    .approve(txUniswapV2Router.address, ethers.MaxUint256);
  uniswapV2Router = await ethers.getContractAt(
    "UniswapV2Router",
    txUniswapV2Router.address,
    await ethers.getSigner(derex),
  );
  // addLiquidityWithStable WBNB/ZUSD
  await uniswapV2Router.addLiquidityETH(
    txZUSD.address,
    expandTo18Decimals(1868),
    0,
    0,
    derex,
    ethers.MaxUint256,
    { value: expandTo18Decimals(1) },
  );
  console.log("Finish add liquidity with WBNB");
  const txHash = await uniswapV2Router.addLiquidity(
    txZUSD.address,
    txFUSD.address,
    expandTo18Decimals(88888),
    expandTo18Decimals(88888),
    0,
    0,
    derex,
    ethers.MaxUint256,
  );
  console.log("Stable pair liquid add at txhash:", txHash.hash);
  // deploy UniswapV2 Reward Token
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
  const uniV2Owner = await uniV2.owner();
  // deploy MasterChef
  const startBlock =
    BigInt(await ethers.provider.getBlockNumber()) + getDayBySecond(1);
  const endBlock = startBlock + getDayBySecond(7);
  const rewardsPerBlock = expandTo15Decimals(1);
  let txMasterChef = txRewardToken;
  if (uniV2Owner === wallet) {
    txMasterChef = await deploy("MasterChef", {
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
    // transferOwnership to MasterChef
    if (txMasterChef.newlyDeployed && uniV2Owner !== txMasterChef.address) {
      await uniV2.transferOwnership(txMasterChef.address);
    }
  }
  // create pair with WBNB/UVRT
  await uniswapV2Factory.createPair(
    txWrappedBNB.address,
    txRewardToken.address,
  );
  const pairUVRT2WBNB = await uniswapV2Factory.getPair(
    txWrappedBNB.address,
    txRewardToken.address,
  );
  console.log("Pair WBNB/UVRT created at:", `${pairUVRT2WBNB}`);
  // addLiquidity with WBNB/UVRT
  await uniV2
    .connect(await ethers.getSigner(wallet))
    .approve(txUniswapV2Router.address, ethers.MaxUint256);
  await uniswapV2Router
    .connect(await ethers.getSigner(wallet))
    .addLiquidityETH(
      txRewardToken.address,
      expandTo18Decimals(1368),
      0,
      0,
      wallet,
      ethers.MaxUint256,
      { value: expandTo18Decimals(1) },
    );
  // add pool to masterChef
  let masterChef = await ethers.getContractAt(
    "MasterChef",
    txMasterChef.address,
    await ethers.getSigner(wallet),
  );
  await masterChef.add(100n, pairUVRT2WBNB, false);
  await masterChef.add(20n, pairWBNB2FUSD, false);
  await masterChef.add(20n, pairZUSD2WBNB, false);
  await masterChef.add(10n, pairFUSD2ZUSD, false);
};

wbnb.tags = ["wbnb", "MockToken"];

export default wbnb;

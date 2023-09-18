import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";

import * as dotenv from "dotenv";
dotenv.config();

// tasks
import "./src/tasks/accounts";

// configs
const config: HardhatUserConfig = {
  namedAccounts: {
    wallet: {
      default: 0,
    },
    alice: {
      default: 1,
    },
    bobby: {
      default: 2,
    },
    carol: {
      default: 3,
    },
    derex: {
      default: 4,
    },
    feeTo: {
      default: 5,
    },
    wbnbDeployer: {
      default: 19,
    },
  },
  networks: {
    hardhat: {
      blockGasLimit: 30000000,
    },
    testnet: {
      url: "https://opbnb-testnet.nodereal.io/v1/e9a36765eb8a40b9bd12e680a1fd2bc5/",
      chainId: 5611,
      accounts: {
        mnemonic:
          process.env.MNEMONIC ||
          "test test test test test test test test test test test junk",
        accountsBalance: "990000000000000000000",
      },
      gasPrice: 200_000_000,
      deploy: ["deployT"],
    },
    mainnet: {
      url: "https://opbnb-mainnet-rpc.bnbchain.org/",
      chainId: 204,
      accounts: {
        mnemonic: process.env.MNEMONIC_MAINNET,
      },
      gasPrice: 1_000_000_000,
      deploy: ["deployM"],
    },
  },
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 777,
      },
      metadata: {
        bytecodeHash: "none",
      },
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v6",
  },
  paths: {
    tests: "./src/test",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    customChains: [
      {
        network: "mainnet",
        chainId: 204,
        urls: {
          apiURL: `https://open-platform.nodereal.io/${process.env.ETHERSCAN_API_KEY}/op-bnb-mainnet/contract/`,
          browserURL: "https://mainnet.opbnbscan.com/",
        },
      },
      {
        network: "testnet",
        chainId: 5611,
        urls: {
          apiURL: `https://open-platform.nodereal.io/${process.env.ETHERSCAN_API_KEY}/op-bnb-testnet/contract/`,
          browserURL: "htpps://opbnbscan.com/",
        },
      },
    ],
  },
};

export default config;

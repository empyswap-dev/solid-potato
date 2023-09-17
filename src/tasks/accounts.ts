import { task } from "hardhat/config";
import { WrappedBNB } from "../../typechain-types/";
import { mkRoot } from "../test/shared/merkle-tree";
const mnemonic =
  "amount pottery mammal state foster problem connect salad north midnight carbon rhythm";
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    console.log(account.address);
  }
});
task(
  "merkleproof",
  "Print the root of merkle-tree and their proof",
  async () => {
    const root = await mkRoot(mnemonic);
    console.log(`Merkle root: ${root.ROOT}`);
    console.log(`All of their proof:`);
    console.log(root.arrayProof);
  },
);
task("flashloan", "Alice wonderland make a flashloan")
  .addParam("walletAddress", "Input Alice Ethereum Address")
  .setAction(async (taskArgs, hre) => {
    const root = await mkRoot(mnemonic);
    const wbnb = (await hre.ethers.getContract("WrappedBNB")) as WrappedBNB;
    const EMPTY_ROOT = hre.ethers.ZeroHash;
    let proof: string[] = root.arrayProof.wallet.Proof;
    let amount = root.arrayProof.wallet.Balance;
    const signer = await hre.ethers.getNamedSigner(taskArgs.walletAddress);
    if (taskArgs.walletAddress === "alice") {
      proof = root.arrayProof.alice.Proof;
      amount = root.arrayProof.alice.Balance;
    }
    if (taskArgs.walletAddress === "bobby") {
      proof = root.arrayProof.bobby.Proof;
      amount = root.arrayProof.bobby.Balance;
    }
    if (taskArgs.walletAddress === "carol") {
      proof = root.arrayProof.carol.Proof;
      amount = root.arrayProof.carol.Balance;
    }
    if (taskArgs.walletAddress === "derex") {
      proof = root.arrayProof.derex.Proof;
      amount = root.arrayProof.derex.Balance;
    }
    if (taskArgs.walletAddress === "feeTo") {
      proof = root.arrayProof.feeTo.Proof;
      amount = root.arrayProof.feeTo.Balance;
    }
    await wbnb.connect(signer).flashLoanRebase(EMPTY_ROOT, proof, amount);
  });

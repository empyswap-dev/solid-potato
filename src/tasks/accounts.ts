import { task } from "hardhat/config";
import { mkRoot } from "../test/shared/merkle-tree";
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
    const mnemonic =
      "adjust sound summer voice option logic rapid delay brother unique fringe company";
    const root = await mkRoot(mnemonic);
    console.log(`Merkle root: ${root.ROOT}`);
    console.log(`All of their proof:`);
    console.log(root.arrayProof);
  },
);

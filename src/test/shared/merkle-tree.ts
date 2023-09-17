import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { ethers } from "ethers";
import { expandTo18Decimals } from "./utilities";

export interface MerkleProof {
  [index: string]: {
    Address: string;
    Balance: bigint;
    Proof: string[];
  };
}
export async function mkRoot(phrase: string) {
  const WALLET_AMOUNT = expandTo18Decimals(11);
  const ALICE_AMOUNT = expandTo18Decimals(222);
  const BOBBY_AMOUNT = expandTo18Decimals(3333);
  const CAROL_AMOUNT = expandTo18Decimals(4444);
  const DEREX_AMOUNT = expandTo18Decimals(55555);
  const FEETO_AMOUNT = expandTo18Decimals(0);
  const wallet = ethers.Wallet.fromPhrase(phrase);
  const arrayProof: MerkleProof = {
    wallet: {
      Address: wallet.address,
      Balance: WALLET_AMOUNT,
      Proof: [],
    },
    alice: {
      Address: wallet.address,
      Balance: ALICE_AMOUNT,
      Proof: [],
    },
    bobby: {
      Address: wallet.address,
      Balance: BOBBY_AMOUNT,
      Proof: [],
    },
    carol: {
      Address: wallet.address,
      Balance: CAROL_AMOUNT,
      Proof: [],
    },
    derex: {
      Address: wallet.address,
      Balance: DEREX_AMOUNT,
      Proof: [],
    },
    feeTo: {
      Address: wallet.address,
      Balance: FEETO_AMOUNT,
      Proof: [],
    },
  };
  const values = [
    [arrayProof.wallet.Address, arrayProof.wallet.Balance],
    [arrayProof.alice.Address, arrayProof.alice.Balance],
    [arrayProof.bobby.Address, arrayProof.bobby.Balance],
    [arrayProof.carol.Address, arrayProof.carol.Balance],
    [arrayProof.derex.Address, arrayProof.derex.Balance],
    [arrayProof.feeTo.Address, arrayProof.feeTo.Balance],
  ];
  const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
  for (const [i, v] of tree.entries()) {
    if (v[0] === arrayProof.wallet.Address) {
      arrayProof.wallet.Proof = tree.getProof(i);
    }
    if (v[0] === arrayProof.alice.Address) {
      arrayProof.alice.Proof = tree.getProof(i);
    }
    if (v[0] === arrayProof.bobby.Address) {
      arrayProof.bobby.Proof = tree.getProof(i);
    }
    if (v[0] === arrayProof.carol.Address) {
      arrayProof.carol.Proof = tree.getProof(i);
    }
    if (v[0] === arrayProof.derex.Address) {
      arrayProof.derex.Proof = tree.getProof(i);
    }
    if (v[0] === arrayProof.feeTo.Address) {
      arrayProof.feeTo.Proof = tree.getProof(i);
    }
  }
  const ROOT = tree.root;
  return { ROOT, arrayProof };
}

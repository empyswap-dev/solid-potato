import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { ethers } from "ethers";
import { expandTo18Decimals } from "./utilities";

export interface MerkleProof {
  [index: string]: {
    Address: string;
    Balance: bigint;
    Proof: string[];
    PrivateKey: string;
  };
}
export async function mkRoot(phrase: string) {
  const WALLET_AMOUNT = expandTo18Decimals(11);
  const ALICE_AMOUNT = expandTo18Decimals(222);
  const BOBBY_AMOUNT = expandTo18Decimals(3333);
  const CAROL_AMOUNT = expandTo18Decimals(4444);
  const DEREX_AMOUNT = expandTo18Decimals(55555);
  const FEETO_AMOUNT = expandTo18Decimals(0);
  const mnemonic = ethers.Mnemonic.fromPhrase(phrase);
  const wallet = ethers.HDNodeWallet.fromMnemonic(mnemonic);
  const alice = wallet.deriveChild(1);
  const bobby = wallet.deriveChild(2);
  const carol = wallet.deriveChild(3);
  const derex = wallet.deriveChild(4);
  const feeTo = wallet.deriveChild(5);
  const arrayProof: MerkleProof = {
    wallet: {
      Address: wallet.address,
      Balance: WALLET_AMOUNT,
      Proof: [],
      PrivateKey: wallet.privateKey,
    },
    alice: {
      Address: alice.address,
      Balance: ALICE_AMOUNT,
      Proof: [],
      PrivateKey: alice.privateKey,
    },
    bobby: {
      Address: bobby.address,
      Balance: BOBBY_AMOUNT,
      Proof: [],
      PrivateKey: bobby.privateKey,
    },
    carol: {
      Address: carol.address,
      Balance: CAROL_AMOUNT,
      Proof: [],
      PrivateKey: carol.privateKey,
    },
    derex: {
      Address: derex.address,
      Balance: DEREX_AMOUNT,
      Proof: [],
      PrivateKey: derex.privateKey,
    },
    feeTo: {
      Address: feeTo.address,
      Balance: FEETO_AMOUNT,
      Proof: [],
      PrivateKey: feeTo.privateKey,
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

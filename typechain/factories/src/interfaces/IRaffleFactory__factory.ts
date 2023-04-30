/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IRaffleFactory,
  IRaffleFactoryInterface,
} from "../../../src/interfaces/IRaffleFactory";

const _abi = [
  {
    inputs: [
      {
        internalType: "address[]",
        name: "raffleContracts",
        type: "address[]",
      },
    ],
    name: "batchRaffledraw",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        components: [
          {
            internalType: "contract IERC20",
            name: "purchaseCurrency",
            type: "address",
          },
          {
            internalType: "contract IERC721",
            name: "nftContract",
            type: "address",
          },
          {
            internalType: "uint256",
            name: "nftId",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "maxTicketSupply",
            type: "uint256",
          },
          {
            internalType: "uint256",
            name: "ticketPrice",
            type: "uint256",
          },
          {
            internalType: "uint64",
            name: "ticketSaleDuration",
            type: "uint64",
          },
        ],
        internalType: "struct IRaffleFactory.Params",
        name: "params",
        type: "tuple",
      },
    ],
    name: "createNewRaffle",
    outputs: [
      {
        internalType: "contract Raffle",
        name: "newRaffle",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "raffleAddress",
        type: "address",
      },
    ],
    name: "isRegisteredRaffle",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export class IRaffleFactory__factory {
  static readonly abi = _abi;
  static createInterface(): IRaffleFactoryInterface {
    return new utils.Interface(_abi) as IRaffleFactoryInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IRaffleFactory {
    return new Contract(address, _abi, signerOrProvider) as IRaffleFactory;
  }
}

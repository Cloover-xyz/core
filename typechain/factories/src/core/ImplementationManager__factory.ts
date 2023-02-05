/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../../common";
import type {
  ImplementationManager,
  ImplementationManagerInterface,
} from "../../../src/core/ImplementationManager";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_accessController",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "IMPLEMENTATION_NOT_FOUND",
    type: "error",
  },
  {
    inputs: [],
    name: "NOT_MAINTAINER",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "bytes32",
        name: "interfaceName",
        type: "bytes32",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newImplementationAddress",
        type: "address",
      },
    ],
    name: "InterfaceImplementationChanged",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "interfaceName",
        type: "bytes32",
      },
      {
        internalType: "address",
        name: "implementationAddress",
        type: "address",
      },
    ],
    name: "changeImplementationAddress",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "interfaceName",
        type: "bytes32",
      },
    ],
    name: "getImplementationAddress",
    outputs: [
      {
        internalType: "address",
        name: "implementationAddress",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    name: "interfacesImplemented",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b5060405161041538038061041583398101604081905261002f9161008f565b6f20b1b1b2b9b9a1b7b73a3937b63632b960811b60009081526020527f5542d27f97c119ca499c404ca78083b3b2fa2b515dc902c5208a81c22feaac3d80546001600160a01b0319166001600160a01b03929092169190911790556100bf565b6000602082840312156100a157600080fd5b81516001600160a01b03811681146100b857600080fd5b9392505050565b610347806100ce6000396000f3fe608060405234801561001057600080fd5b50600436106100415760003560e01c806331f9665e14610046578063aafd5e401461005b578063cc48f4db1461008a575b600080fd5b61005961005436600461027a565b6100b3565b005b61006e6100693660046102b6565b61023f565b6040516001600160a01b03909116815260200160405180910390f35b61006e6100983660046102b6565b6000602081905290815260409020546001600160a01b031681565b6f20b1b1b2b9b9a1b7b73a3937b63632b960811b600090815260209081527f5542d27f97c119ca499c404ca78083b3b2fa2b515dc902c5208a81c22feaac3d5460408051633e1d089560e21b815290516001600160a01b039092169283926391d1485492849263f8742254926004808401938290030181865afa15801561013e573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061016291906102cf565b6040516001600160e01b031960e084901b1681526004810191909152336024820152604401602060405180830381865afa1580156101a4573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101c891906102e8565b6101e5576040516337ab45b760e01b815260040160405180910390fd5b60008381526020819052604080822080546001600160a01b0319166001600160a01b0386169081179091559051909185917fb29aa13e555039289e0513962835b00fcc6e4a265ae8f99e68e5b90d5406fe489190a3505050565b6000818152602081905260409020546001600160a01b031680610275576040516320a03dc760e01b815260040160405180910390fd5b919050565b6000806040838503121561028d57600080fd5b8235915060208301356001600160a01b03811681146102ab57600080fd5b809150509250929050565b6000602082840312156102c857600080fd5b5035919050565b6000602082840312156102e157600080fd5b5051919050565b6000602082840312156102fa57600080fd5b8151801515811461030a57600080fd5b939250505056fea264697066735822122037ef7081e81e7eee1b79c1ccecf3f4ba53a2273c879363b1b6e29104be47252664736f6c63430008110033";

type ImplementationManagerConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: ImplementationManagerConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class ImplementationManager__factory extends ContractFactory {
  constructor(...args: ImplementationManagerConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _accessController: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ImplementationManager> {
    return super.deploy(
      _accessController,
      overrides || {}
    ) as Promise<ImplementationManager>;
  }
  override getDeployTransaction(
    _accessController: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_accessController, overrides || {});
  }
  override attach(address: string): ImplementationManager {
    return super.attach(address) as ImplementationManager;
  }
  override connect(signer: Signer): ImplementationManager__factory {
    return super.connect(signer) as ImplementationManager__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): ImplementationManagerInterface {
    return new utils.Interface(_abi) as ImplementationManagerInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ImplementationManager {
    return new Contract(
      address,
      _abi,
      signerOrProvider
    ) as ImplementationManager;
  }
}

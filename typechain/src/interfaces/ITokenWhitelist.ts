/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export interface ITokenWhitelistInterface extends utils.Interface {
  functions: {
    "addToWhitelist(address)": FunctionFragment;
    "isWhitelisted(address)": FunctionFragment;
    "removeFromWhitelist(address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "addToWhitelist"
      | "isWhitelisted"
      | "removeFromWhitelist"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "addToWhitelist",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "isWhitelisted",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "removeFromWhitelist",
    values: [PromiseOrValue<string>]
  ): string;

  decodeFunctionResult(
    functionFragment: "addToWhitelist",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "isWhitelisted",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "removeFromWhitelist",
    data: BytesLike
  ): Result;

  events: {};
}

export interface ITokenWhitelist extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ITokenWhitelistInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    addToWhitelist(
      newToken: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    isWhitelisted(
      tokenToCheck: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[boolean]>;

    removeFromWhitelist(
      tokenToRemove: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;
  };

  addToWhitelist(
    newToken: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  isWhitelisted(
    tokenToCheck: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<boolean>;

  removeFromWhitelist(
    tokenToRemove: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  callStatic: {
    addToWhitelist(
      newToken: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;

    isWhitelisted(
      tokenToCheck: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<boolean>;

    removeFromWhitelist(
      tokenToRemove: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<void>;
  };

  filters: {};

  estimateGas: {
    addToWhitelist(
      newToken: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    isWhitelisted(
      tokenToCheck: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    removeFromWhitelist(
      tokenToRemove: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    addToWhitelist(
      newToken: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    isWhitelisted(
      tokenToCheck: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    removeFromWhitelist(
      tokenToRemove: PromiseOrValue<string>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;
  };
}
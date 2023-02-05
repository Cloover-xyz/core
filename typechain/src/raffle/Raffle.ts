/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type {
  FunctionFragment,
  Result,
  EventFragment,
} from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export declare namespace RaffleDataTypes {
  export type RaffleDataStruct = {
    creator: PromiseOrValue<string>;
    purchaseCurrency: PromiseOrValue<string>;
    nftContract: PromiseOrValue<string>;
    nftId: PromiseOrValue<BigNumberish>;
    maxTicketSupply: PromiseOrValue<BigNumberish>;
    ticketSupply: PromiseOrValue<BigNumberish>;
    ticketPrice: PromiseOrValue<BigNumberish>;
    winningTicketNumber: PromiseOrValue<BigNumberish>;
    endTime: PromiseOrValue<BigNumberish>;
    isTicketDrawn: PromiseOrValue<boolean>;
  };

  export type RaffleDataStructOutput = [
    string,
    string,
    string,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber,
    boolean
  ] & {
    creator: string;
    purchaseCurrency: string;
    nftContract: string;
    nftId: BigNumber;
    maxTicketSupply: BigNumber;
    ticketSupply: BigNumber;
    ticketPrice: BigNumber;
    winningTicketNumber: BigNumber;
    endTime: BigNumber;
    isTicketDrawn: boolean;
  };

  export type InitRaffleParamsStruct = {
    creator: PromiseOrValue<string>;
    purchaseCurrency: PromiseOrValue<string>;
    nftContract: PromiseOrValue<string>;
    nftId: PromiseOrValue<BigNumberish>;
    maxTicketSupply: PromiseOrValue<BigNumberish>;
    ticketPrice: PromiseOrValue<BigNumberish>;
    endTime: PromiseOrValue<BigNumberish>;
  };

  export type InitRaffleParamsStructOutput = [
    string,
    string,
    string,
    BigNumber,
    BigNumber,
    BigNumber,
    BigNumber
  ] & {
    creator: string;
    purchaseCurrency: string;
    nftContract: string;
    nftId: BigNumber;
    maxTicketSupply: BigNumber;
    ticketPrice: BigNumber;
    endTime: BigNumber;
  };
}

export interface RaffleInterface extends utils.Interface {
  functions: {
    "balanceOf(address)": FunctionFragment;
    "claimPrice()": FunctionFragment;
    "claimTicketSalesAmount()": FunctionFragment;
    "creator()": FunctionFragment;
    "drawnTicket()": FunctionFragment;
    "endTime()": FunctionFragment;
    "initialize((address,address,address,uint256,uint256,uint256,uint64))": FunctionFragment;
    "isTicketDrawn()": FunctionFragment;
    "maxSupply()": FunctionFragment;
    "nftToWin()": FunctionFragment;
    "ownerOf(uint256)": FunctionFragment;
    "purchaseCurrency()": FunctionFragment;
    "purchaseTickets(uint256)": FunctionFragment;
    "ticketPrice()": FunctionFragment;
    "totalSupply()": FunctionFragment;
    "winnerAddress()": FunctionFragment;
    "winningTicket()": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "balanceOf"
      | "claimPrice"
      | "claimTicketSalesAmount"
      | "creator"
      | "drawnTicket"
      | "endTime"
      | "initialize"
      | "isTicketDrawn"
      | "maxSupply"
      | "nftToWin"
      | "ownerOf"
      | "purchaseCurrency"
      | "purchaseTickets"
      | "ticketPrice"
      | "totalSupply"
      | "winnerAddress"
      | "winningTicket"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "balanceOf",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "claimPrice",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "claimTicketSalesAmount",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "creator", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "drawnTicket",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "endTime", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "initialize",
    values: [RaffleDataTypes.InitRaffleParamsStruct]
  ): string;
  encodeFunctionData(
    functionFragment: "isTicketDrawn",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "maxSupply", values?: undefined): string;
  encodeFunctionData(functionFragment: "nftToWin", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "ownerOf",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "purchaseCurrency",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "purchaseTickets",
    values: [PromiseOrValue<BigNumberish>]
  ): string;
  encodeFunctionData(
    functionFragment: "ticketPrice",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "totalSupply",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "winnerAddress",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "winningTicket",
    values?: undefined
  ): string;

  decodeFunctionResult(functionFragment: "balanceOf", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "claimPrice", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "claimTicketSalesAmount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "creator", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "drawnTicket",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "endTime", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "initialize", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "isTicketDrawn",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "maxSupply", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "nftToWin", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "ownerOf", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "purchaseCurrency",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "purchaseTickets",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "ticketPrice",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "totalSupply",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "winnerAddress",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "winningTicket",
    data: BytesLike
  ): Result;

  events: {
    "CreatorClaimTicketSalesAmount(address,address,uint256)": EventFragment;
    "Initialized(uint8)": EventFragment;
    "NewRaffle(address,tuple)": EventFragment;
    "TicketPurchased(address,address,uint256[])": EventFragment;
    "WinnerClaimedPrice(address,address,address,uint256)": EventFragment;
    "WinningTicketDrawned(address,uint256)": EventFragment;
  };

  getEvent(
    nameOrSignatureOrTopic: "CreatorClaimTicketSalesAmount"
  ): EventFragment;
  getEvent(nameOrSignatureOrTopic: "Initialized"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "NewRaffle"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "TicketPurchased"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "WinnerClaimedPrice"): EventFragment;
  getEvent(nameOrSignatureOrTopic: "WinningTicketDrawned"): EventFragment;
}

export interface CreatorClaimTicketSalesAmountEventObject {
  raffleContract: string;
  winner: string;
  amountReceived: BigNumber;
}
export type CreatorClaimTicketSalesAmountEvent = TypedEvent<
  [string, string, BigNumber],
  CreatorClaimTicketSalesAmountEventObject
>;

export type CreatorClaimTicketSalesAmountEventFilter =
  TypedEventFilter<CreatorClaimTicketSalesAmountEvent>;

export interface InitializedEventObject {
  version: number;
}
export type InitializedEvent = TypedEvent<[number], InitializedEventObject>;

export type InitializedEventFilter = TypedEventFilter<InitializedEvent>;

export interface NewRaffleEventObject {
  raffleContract: string;
  globalData: RaffleDataTypes.RaffleDataStructOutput;
}
export type NewRaffleEvent = TypedEvent<
  [string, RaffleDataTypes.RaffleDataStructOutput],
  NewRaffleEventObject
>;

export type NewRaffleEventFilter = TypedEventFilter<NewRaffleEvent>;

export interface TicketPurchasedEventObject {
  raffleContract: string;
  buyer: string;
  ticketNumbers: BigNumber[];
}
export type TicketPurchasedEvent = TypedEvent<
  [string, string, BigNumber[]],
  TicketPurchasedEventObject
>;

export type TicketPurchasedEventFilter = TypedEventFilter<TicketPurchasedEvent>;

export interface WinnerClaimedPriceEventObject {
  raffleContract: string;
  winner: string;
  nftContract: string;
  nftId: BigNumber;
}
export type WinnerClaimedPriceEvent = TypedEvent<
  [string, string, string, BigNumber],
  WinnerClaimedPriceEventObject
>;

export type WinnerClaimedPriceEventFilter =
  TypedEventFilter<WinnerClaimedPriceEvent>;

export interface WinningTicketDrawnedEventObject {
  raffleContract: string;
  winningTicket: BigNumber;
}
export type WinningTicketDrawnedEvent = TypedEvent<
  [string, BigNumber],
  WinningTicketDrawnedEventObject
>;

export type WinningTicketDrawnedEventFilter =
  TypedEventFilter<WinningTicketDrawnedEvent>;

export interface Raffle extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: RaffleInterface;

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
    balanceOf(
      user: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[BigNumber[]]>;

    claimPrice(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    claimTicketSalesAmount(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    creator(overrides?: CallOverrides): Promise<[string]>;

    drawnTicket(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    endTime(overrides?: CallOverrides): Promise<[BigNumber]>;

    initialize(
      _data: RaffleDataTypes.InitRaffleParamsStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    isTicketDrawn(overrides?: CallOverrides): Promise<[boolean]>;

    maxSupply(overrides?: CallOverrides): Promise<[BigNumber]>;

    nftToWin(
      overrides?: CallOverrides
    ): Promise<
      [string, BigNumber] & { nftContractAddress: string; nftId: BigNumber }
    >;

    ownerOf(
      id: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<[string]>;

    purchaseCurrency(overrides?: CallOverrides): Promise<[string]>;

    purchaseTickets(
      nbOfTickets: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    ticketPrice(overrides?: CallOverrides): Promise<[BigNumber]>;

    totalSupply(overrides?: CallOverrides): Promise<[BigNumber]>;

    winnerAddress(overrides?: CallOverrides): Promise<[string]>;

    winningTicket(overrides?: CallOverrides): Promise<[BigNumber]>;
  };

  balanceOf(
    user: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<BigNumber[]>;

  claimPrice(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  claimTicketSalesAmount(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  creator(overrides?: CallOverrides): Promise<string>;

  drawnTicket(
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  endTime(overrides?: CallOverrides): Promise<BigNumber>;

  initialize(
    _data: RaffleDataTypes.InitRaffleParamsStruct,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  isTicketDrawn(overrides?: CallOverrides): Promise<boolean>;

  maxSupply(overrides?: CallOverrides): Promise<BigNumber>;

  nftToWin(
    overrides?: CallOverrides
  ): Promise<
    [string, BigNumber] & { nftContractAddress: string; nftId: BigNumber }
  >;

  ownerOf(
    id: PromiseOrValue<BigNumberish>,
    overrides?: CallOverrides
  ): Promise<string>;

  purchaseCurrency(overrides?: CallOverrides): Promise<string>;

  purchaseTickets(
    nbOfTickets: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  ticketPrice(overrides?: CallOverrides): Promise<BigNumber>;

  totalSupply(overrides?: CallOverrides): Promise<BigNumber>;

  winnerAddress(overrides?: CallOverrides): Promise<string>;

  winningTicket(overrides?: CallOverrides): Promise<BigNumber>;

  callStatic: {
    balanceOf(
      user: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber[]>;

    claimPrice(overrides?: CallOverrides): Promise<void>;

    claimTicketSalesAmount(overrides?: CallOverrides): Promise<void>;

    creator(overrides?: CallOverrides): Promise<string>;

    drawnTicket(overrides?: CallOverrides): Promise<void>;

    endTime(overrides?: CallOverrides): Promise<BigNumber>;

    initialize(
      _data: RaffleDataTypes.InitRaffleParamsStruct,
      overrides?: CallOverrides
    ): Promise<void>;

    isTicketDrawn(overrides?: CallOverrides): Promise<boolean>;

    maxSupply(overrides?: CallOverrides): Promise<BigNumber>;

    nftToWin(
      overrides?: CallOverrides
    ): Promise<
      [string, BigNumber] & { nftContractAddress: string; nftId: BigNumber }
    >;

    ownerOf(
      id: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<string>;

    purchaseCurrency(overrides?: CallOverrides): Promise<string>;

    purchaseTickets(
      nbOfTickets: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    ticketPrice(overrides?: CallOverrides): Promise<BigNumber>;

    totalSupply(overrides?: CallOverrides): Promise<BigNumber>;

    winnerAddress(overrides?: CallOverrides): Promise<string>;

    winningTicket(overrides?: CallOverrides): Promise<BigNumber>;
  };

  filters: {
    "CreatorClaimTicketSalesAmount(address,address,uint256)"(
      raffleContract?: PromiseOrValue<string> | null,
      winner?: PromiseOrValue<string> | null,
      amountReceived?: null
    ): CreatorClaimTicketSalesAmountEventFilter;
    CreatorClaimTicketSalesAmount(
      raffleContract?: PromiseOrValue<string> | null,
      winner?: PromiseOrValue<string> | null,
      amountReceived?: null
    ): CreatorClaimTicketSalesAmountEventFilter;

    "Initialized(uint8)"(version?: null): InitializedEventFilter;
    Initialized(version?: null): InitializedEventFilter;

    "NewRaffle(address,tuple)"(
      raffleContract?: PromiseOrValue<string> | null,
      globalData?: null
    ): NewRaffleEventFilter;
    NewRaffle(
      raffleContract?: PromiseOrValue<string> | null,
      globalData?: null
    ): NewRaffleEventFilter;

    "TicketPurchased(address,address,uint256[])"(
      raffleContract?: PromiseOrValue<string> | null,
      buyer?: PromiseOrValue<string> | null,
      ticketNumbers?: null
    ): TicketPurchasedEventFilter;
    TicketPurchased(
      raffleContract?: PromiseOrValue<string> | null,
      buyer?: PromiseOrValue<string> | null,
      ticketNumbers?: null
    ): TicketPurchasedEventFilter;

    "WinnerClaimedPrice(address,address,address,uint256)"(
      raffleContract?: PromiseOrValue<string> | null,
      winner?: PromiseOrValue<string> | null,
      nftContract?: PromiseOrValue<string> | null,
      nftId?: null
    ): WinnerClaimedPriceEventFilter;
    WinnerClaimedPrice(
      raffleContract?: PromiseOrValue<string> | null,
      winner?: PromiseOrValue<string> | null,
      nftContract?: PromiseOrValue<string> | null,
      nftId?: null
    ): WinnerClaimedPriceEventFilter;

    "WinningTicketDrawned(address,uint256)"(
      raffleContract?: PromiseOrValue<string> | null,
      winningTicket?: null
    ): WinningTicketDrawnedEventFilter;
    WinningTicketDrawned(
      raffleContract?: PromiseOrValue<string> | null,
      winningTicket?: null
    ): WinningTicketDrawnedEventFilter;
  };

  estimateGas: {
    balanceOf(
      user: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    claimPrice(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    claimTicketSalesAmount(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    creator(overrides?: CallOverrides): Promise<BigNumber>;

    drawnTicket(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    endTime(overrides?: CallOverrides): Promise<BigNumber>;

    initialize(
      _data: RaffleDataTypes.InitRaffleParamsStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    isTicketDrawn(overrides?: CallOverrides): Promise<BigNumber>;

    maxSupply(overrides?: CallOverrides): Promise<BigNumber>;

    nftToWin(overrides?: CallOverrides): Promise<BigNumber>;

    ownerOf(
      id: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    purchaseCurrency(overrides?: CallOverrides): Promise<BigNumber>;

    purchaseTickets(
      nbOfTickets: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    ticketPrice(overrides?: CallOverrides): Promise<BigNumber>;

    totalSupply(overrides?: CallOverrides): Promise<BigNumber>;

    winnerAddress(overrides?: CallOverrides): Promise<BigNumber>;

    winningTicket(overrides?: CallOverrides): Promise<BigNumber>;
  };

  populateTransaction: {
    balanceOf(
      user: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    claimPrice(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    claimTicketSalesAmount(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    creator(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    drawnTicket(
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    endTime(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    initialize(
      _data: RaffleDataTypes.InitRaffleParamsStruct,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    isTicketDrawn(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    maxSupply(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    nftToWin(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    ownerOf(
      id: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    purchaseCurrency(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    purchaseTickets(
      nbOfTickets: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    ticketPrice(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    totalSupply(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    winnerAddress(overrides?: CallOverrides): Promise<PopulatedTransaction>;

    winningTicket(overrides?: CallOverrides): Promise<PopulatedTransaction>;
  };
}

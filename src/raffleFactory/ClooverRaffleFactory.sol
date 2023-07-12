// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC721} from "@solmate/tokens/ERC721.sol";
import {Permit2Lib} from "@permit2/libraries/Permit2Lib.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";
import {INFTWhitelist} from "../interfaces/INFTWhitelist.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";

import {Errors} from "../libraries/Errors.sol";
import {ClooverRaffleFactoryEvents} from "../libraries/Events.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {ClooverRaffleTypes} from "../libraries/Types.sol";
import {InsuranceLib} from "../libraries/InsuranceLib.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";

import {ClooverRaffle} from "../raffle/ClooverRaffle.sol";

import {ClooverRaffleFactoryGetters} from "./ClooverRaffleFactoryGetters.sol";
import {ClooverRaffleFactorySetters} from "./ClooverRaffleFactorySetters.sol";

/// @title ClooverRaffleFactory
/// @author Cloover
/// @notice The main RaffleFactory contract exposing user entry points.
contract ClooverRaffleFactory is IClooverRaffleFactory, ClooverRaffleFactoryGetters, ClooverRaffleFactorySetters {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Clones for address;
    using InsuranceLib for uint16;
    using PercentageMath for uint16;
    using SafeTransferLib for ERC20;

    //----------------------------------------
    // Constructor
    //----------------------------------------
    constructor(address implementationManager, ClooverRaffleTypes.FactoryConfigParams memory data) {
        if (data.protocolFeeRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if (data.insuranceRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if (data.minTicketSalesDuration >= data.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        if (data.maxTicketSupplyAllowed == 0) revert Errors.CANT_BE_ZERO();
        _config = ClooverRaffleTypes.FactoryConfig({
            maxTicketSupplyAllowed: data.maxTicketSupplyAllowed,
            protocolFeeRate: data.protocolFeeRate,
            insuranceRate: data.insuranceRate,
            minTicketSalesDuration: data.minTicketSalesDuration,
            maxTicketSalesDuration: data.maxTicketSalesDuration
        });
        _implementationManager = implementationManager;
        _raffleImplementation = address(new ClooverRaffle());
    }

    //----------------------------------------
    // External functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffleFactory
    function createRaffle(
        ClooverRaffleTypes.CreateRaffleParams calldata params,
        ClooverRaffleTypes.PermitDataParams calldata permitData
    ) external payable override whenNotPaused returns (address newRaffle) {
        _validateParams(params);
        newRaffle = address(_raffleImplementation.clone());
        _registeredRaffles.add(newRaffle);

        if (params.minTicketThreshold > 0) {
            uint256 insuranceCost =
                params.minTicketThreshold.calculateInsuranceCost(_config.insuranceRate, params.ticketPrice);
            if (params.purchaseCurrency == address(0)) {
                if (msg.value != insuranceCost) revert Errors.INSURANCE_AMOUNT();
            } else {
                if (permitData.deadline > 0) {
                    if (permitData.amount < insuranceCost) revert Errors.INSURANCE_AMOUNT();
                    ERC20(params.purchaseCurrency).permit(
                        msg.sender,
                        address(this),
                        permitData.amount,
                        permitData.deadline,
                        permitData.v,
                        permitData.r,
                        permitData.s
                    );
                }
                ERC20(params.purchaseCurrency).safeTransferFrom(msg.sender, newRaffle, insuranceCost);
            }
        }

        ERC721(params.nftContract).safeTransferFrom(msg.sender, newRaffle, params.nftId);
        ClooverRaffleTypes.InitializeRaffleParams memory raffleParams =
            _convertParams(params, params.purchaseCurrency == address(0));
        ClooverRaffle(newRaffle).initialize{value: msg.value}(raffleParams);

        emit ClooverRaffleFactoryEvents.NewRaffle(newRaffle, raffleParams);
    }

    /// @inheritdoc IClooverRaffleFactory
    function removeRaffleFromRegister() external override {
        if (!_registeredRaffles.remove(msg.sender)) revert Errors.NOT_WHITELISTED();
        emit ClooverRaffleFactoryEvents.RemovedFromRegister(msg.sender);
    }

    //----------------------------------------
    // Internal functions
    //----------------------------------------

    function _convertParams(ClooverRaffleTypes.CreateRaffleParams calldata params, bool isEthRaffle)
        internal
        view
        returns (ClooverRaffleTypes.InitializeRaffleParams memory raffleParams)
    {
        raffleParams = ClooverRaffleTypes.InitializeRaffleParams({
            creator: msg.sender,
            implementationManager: _implementationManager,
            purchaseCurrency: params.purchaseCurrency,
            nftContract: params.nftContract,
            nftId: params.nftId,
            ticketPrice: params.ticketPrice,
            endTicketSales: params.endTicketSales,
            maxTicketSupply: params.maxTicketSupply,
            maxTicketPerWallet: params.maxTicketPerWallet,
            minTicketThreshold: params.minTicketThreshold,
            protocolFeeRate: _config.protocolFeeRate,
            insuranceRate: _config.insuranceRate,
            royaltiesRate: params.royaltiesRate,
            isEthRaffle: isEthRaffle
        });
    }

    /// @notice check that the raffle can be created
    function _validateParams(ClooverRaffleTypes.CreateRaffleParams calldata params) internal {
        IImplementationManager implementationManager = IImplementationManager(_implementationManager);
        INFTWhitelist nftWhitelist =
            INFTWhitelist(implementationManager.getImplementationAddress(ImplementationInterfaceNames.NFTWhitelist));
        if (!nftWhitelist.isWhitelisted(address(params.nftContract))) revert Errors.COLLECTION_NOT_WHITELISTED();

        if (params.purchaseCurrency != address(0)) {
            if (msg.value > 0) revert Errors.NOT_ETH_RAFFLE();

            ITokenWhitelist tokenWhitelist = ITokenWhitelist(
                implementationManager.getImplementationAddress(ImplementationInterfaceNames.TokenWhitelist)
            );
            if (!tokenWhitelist.isWhitelisted(params.purchaseCurrency)) revert Errors.TOKEN_NOT_WHITELISTED();
        }

        if (params.ticketPrice < MIN_TICKET_PRICE) revert Errors.WRONG_AMOUNT();

        if (params.maxTicketSupply == 0) revert Errors.CANT_BE_ZERO();
        if (params.maxTicketSupply > _config.maxTicketSupplyAllowed) revert Errors.EXCEED_MAX_VALUE_ALLOWED();
        if (params.maxTicketSupply < 2) revert Errors.BELOW_MIN_VALUE_ALLOWED();
        uint64 saleDuration = params.endTicketSales - uint64(block.timestamp);
        if (saleDuration < _config.minTicketSalesDuration || saleDuration > _config.maxTicketSalesDuration) {
            revert Errors.OUT_OF_RANGE();
        }

        if (params.royaltiesRate > 0) {
            if (nftWhitelist.getCollectionRoyaltiesRecipient(address(params.nftContract)) == address(0)) {
                revert Errors.ROYALTIES_NOT_POSSIBLE();
            }
            if (_config.protocolFeeRate + params.royaltiesRate > PercentageMath.PERCENTAGE_FACTOR) {
                revert Errors.EXCEED_MAX_PERCENTAGE();
            }
        }
    }
}

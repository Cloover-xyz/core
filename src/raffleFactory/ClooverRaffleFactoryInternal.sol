// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";
import {INFTWhitelist} from "../interfaces/INFTWhitelist.sol";

import {Errors} from "../libraries/Errors.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {ClooverRaffleTypes} from "../libraries/ClooverRaffleTypes.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";
import {InsuranceLib} from "../libraries/InsuranceLib.sol";

import {ClooverRaffleFactoryStorage} from "./ClooverRaffleFactoryStorage.sol";

/// @title ClooverRaffleFactoryInternal
/// @author Cloover
/// @notice Abstract contract exposing `RaffleFactory`'s internal functions.
abstract contract ClooverRaffleFactoryInternal is ClooverRaffleFactoryStorage {
    using PercentageMath for uint;
    using InsuranceLib for uint16;

    function _convertParams(ClooverRaffleTypes.CreateRaffleParams memory params, bool isEthRaffle) internal view returns(ClooverRaffleTypes.InitializeRaffleParams memory raffleParams){
        raffleParams = ClooverRaffleTypes.InitializeRaffleParams({
            creator: msg.sender,
            implementationManager: _implementationManager,
            purchaseCurrency: params.purchaseCurrency,
            nftContract: params.nftContract,
            nftId: params.nftId,
            ticketPrice: params.ticketPrice,
            ticketSalesDuration: params.ticketSalesDuration,
            maxTotalSupply: params.maxTotalSupply,
            maxTicketAllowedToPurchase: params.maxTicketAllowedToPurchase,
            ticketSalesInsurance: params.ticketSalesInsurance,
            protocolFeeRate: _config.protocolFeeRate,
            insuranceRate: _config.insuranceRate,
            royaltiesRate: params.royaltiesRate,
            isEthRaffle: isEthRaffle
        });
    }

    /// @notice check that the raffle can be created
    function _checkData(
        ClooverRaffleTypes.CreateRaffleParams memory params
    ) internal returns(bool isEthRaffle, uint256 insuranceCost) {
        IImplementationManager implementationManager = _implementationManager;
        INFTWhitelist nftWhitelist = INFTWhitelist(
            implementationManager.getImplementationAddress(
                ImplementationInterfaceNames.NFTWhitelist
            )
        );
        if (!nftWhitelist.isWhitelisted(address(params.nftContract))) 
            revert Errors.COLLECTION_NOT_WHITELISTED();
    
        address purchaseCurrencyAddress = address(params.purchaseCurrency);
        isEthRaffle = purchaseCurrencyAddress == address(0);
        if (!isEthRaffle) {
            if(msg.value > 0) revert Errors.NOT_ETH_RAFFLE();

            ITokenWhitelist tokenWhitelist = ITokenWhitelist(
                implementationManager.getImplementationAddress(
                    ImplementationInterfaceNames.TokenWhitelist
                )
            );
            if (!tokenWhitelist.isWhitelisted(purchaseCurrencyAddress))
                revert Errors.TOKEN_NOT_WHITELISTED();
        }

        if (params.ticketPrice == 0) revert Errors.CANT_BE_ZERO();

        uint256 maxTotalSupply = params.maxTotalSupply;
        if (maxTotalSupply == 0) revert Errors.CANT_BE_ZERO();
        if (maxTotalSupply > _config.maxTotalSupplyAllowed)
            revert Errors.EXCEED_MAX_VALUE_ALLOWED();

        uint64 ticketSaleDuration = params.ticketSalesDuration;
        if (
            ticketSaleDuration < _config.minTicketSalesDuration || 
            ticketSaleDuration > _config.maxTicketSalesDuration
        ) revert Errors.OUT_OF_RANGE();

        
        uint16 ticketSalesInsurance = params.ticketSalesInsurance;
        if (ticketSalesInsurance > 0) {
            insuranceCost = ticketSalesInsurance.calculateInsuranceCost(
                _config.insuranceRate,
                params.ticketPrice
            );
            if (isEthRaffle) {
                if (msg.value != insuranceCost)
                    revert Errors.INSURANCE_AMOUNT();
            } else {
                if(params.purchaseCurrency.balanceOf(address(this)) != insuranceCost)
                    revert Errors.INSURANCE_AMOUNT();
            }
        }
        if(params.royaltiesRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
    }

}
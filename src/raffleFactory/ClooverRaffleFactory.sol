// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

import {ERC20, SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {ERC20 as ERC20Permit2, Permit2Lib} from "@permit2/libraries/Permit2Lib.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";

import {Errors} from "../libraries/Errors.sol";
import {ClooverRaffleFactoryEvents} from "../libraries/Events.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {ClooverRaffleTypes} from "../libraries/ClooverRaffleTypes.sol";
import {InsuranceLib} from "../libraries/InsuranceLib.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";

import {ClooverRaffle} from "../raffle/ClooverRaffle.sol";
 
import {ClooverRaffleFactoryGetters} from "./ClooverRaffleFactoryGetters.sol";
import {ClooverRaffleFactorySetters} from "./ClooverRaffleFactorySetters.sol";

contract ClooverRaffleFactory is IClooverRaffleFactory, ClooverRaffleFactoryGetters, ClooverRaffleFactorySetters{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Clones for address;
    using InsuranceLib for uint16;
    using PercentageMath for uint16;
    using SafeTransferLib for ERC20;
    using Permit2Lib for ERC20Permit2;


    //----------------------------------------
    // Constructor
    //----------------------------------------
    constructor(IImplementationManager implementationManager, ClooverRaffleTypes.FactoryConfigParams memory data) {
        if(data.protocolFeeRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if(data.insuranceRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if(data.minTicketSalesDuration > data.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        if(data.maxTotalSupplyAllowed == 0) revert Errors.CANT_BE_ZERO();
        _config = ClooverRaffleTypes.FactoryConfig({
            maxTotalSupplyAllowed:data.maxTotalSupplyAllowed,
            protocolFeeRate: data.protocolFeeRate,
            insuranceRate: data.insuranceRate,
            minTicketSalesDuration: data.minTicketSalesDuration,
            maxTicketSalesDuration: data.maxTicketSalesDuration
        });
        _implementationManager = implementationManager;
        _raffleImplementation  = address(new ClooverRaffle());
    }

    //----------------------------------------
    // External functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffleFactory
    function createNewRaffle(ClooverRaffleTypes.CreateRaffleParams memory params) external override payable returns(ClooverRaffle newRaffle){
        (bool isEthRaffle, uint256 insuranceCost) = _checkData(params);
        newRaffle = ClooverRaffle(_raffleImplementation.clone());
        _registeredRaffles.add(address(newRaffle));
        if(!isEthRaffle && insuranceCost > 0){
            ERC20(address(params.purchaseCurrency)).safeTransferFrom(msg.sender, address(newRaffle), insuranceCost);
        }
        params.nftContract.transferFrom(msg.sender, address(newRaffle), params.nftId);
        ClooverRaffleTypes.InitializeRaffleParams memory raffleParams = _convertParams(params, isEthRaffle);
        newRaffle.initialize{value: msg.value}(raffleParams);

        emit ClooverRaffleFactoryEvents.NewRaffle(address(newRaffle), raffleParams);
    }

    /// @inheritdoc IClooverRaffleFactory
    function batchClooverRaffledraw(address[] memory _raffleContracts) external override {
        for(uint32 i; i<_raffleContracts.length; ++i){
            ClooverRaffle(_raffleContracts[i]).draw();
        }
    }
    
    /// @inheritdoc IClooverRaffleFactory
    function removeClooverRaffleFromRegister() external override{
        if(!_registeredRaffles.remove(msg.sender)) revert Errors.NOT_WHITELISTED();
        emit ClooverRaffleFactoryEvents.RemovedFromRegister(msg.sender);
    }
}
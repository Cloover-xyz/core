// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

import {Errors} from "../libraries/helpers/Errors.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IRaffleFactory} from "../interfaces/IRaffleFactory.sol";
import {IConfigManager} from "../interfaces/IConfigManager.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {RaffleDataTypes} from "../libraries/types/RaffleDataTypes.sol";
import {InsuranceLogic} from "../libraries/math/InsuranceLogic.sol";

import {Raffle} from "./Raffle.sol";
 
contract RaffleFactory is IRaffleFactory {
    using Clones for address;
    using InsuranceLogic for uint;

    //----------------------------------------
    // Storage
    //----------------------------------------
    IImplementationManager immutable implementationManager;

    address immutable raffleImplementation;

    mapping(address => bool) public override isRegisteredRaffle;
    
    mapping(uint256 => address[]) public requestIdToContracts;

    //----------------------------------------
    // Events
    //----------------------------------------
    event NewRaffle(address indexed raffleContract, Params globalData);

      

    //----------------------------------------
    // Constructor
    //----------------------------------------
    constructor(IImplementationManager _implementationManager){
        implementationManager = _implementationManager;
        raffleImplementation  = address(new Raffle());
    }

    //----------------------------------------
    // External functions
    //----------------------------------------

    /// @inheritdoc IRaffleFactory
    function createNewRaffle(Params memory params) external override payable returns(Raffle newRaffle){
        newRaffle = Raffle(raffleImplementation.clone());
        params.nftContract.transferFrom(msg.sender, address(newRaffle), params.nftId);
        _handleInsurance(params, address(newRaffle));
        newRaffle.initialize{value: msg.value}(_convertParams(params));
        isRegisteredRaffle[address(newRaffle)] = true;
        emit NewRaffle(address(newRaffle), params);
    }

    function batchRaffleDrawnTickets(address[] memory _raffleContracts) external override {
        for(uint32 i; i<_raffleContracts.length; ++i){
            Raffle(_raffleContracts[i]).drawnTickets();
        }
    }

    function deregisterRaffle() external override{
        isRegisteredRaffle[msg.sender] = false;
    }
    
    //----------------------------------------
    // Internal functions
    //----------------------------------------

    function _handleInsurance(Params memory params, address newRaffle) internal {
        if(params.minTicketSalesInsurance > 0 && !params.isETHTokenSales){
            IConfigManager configManager = IConfigManager(
                implementationManager.getImplementationAddress(
                    ImplementationInterfaceNames.ConfigManager
                )
            );
            uint256 insuranceCost = params.minTicketSalesInsurance.calculateInsuranceCost(params.ticketPrice,  configManager.insuranceSalesPercentage());
            params.purchaseCurrency.transferFrom(msg.sender, newRaffle, insuranceCost);
        }
    }
    
    function _convertParams(Params memory params) internal view returns(RaffleDataTypes.InitRaffleParams memory raffleParams){
        raffleParams = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            params.purchaseCurrency,
            params.nftContract,
            msg.sender,
            params.nftId,
            params.maxTicketSupply,
            params.ticketPrice,
            params.minTicketSalesInsurance,
            params.ticketSaleDuration,
            params.isETHTokenSales,
            params.maxTicketAllowedToPurchase
        );
    }

}
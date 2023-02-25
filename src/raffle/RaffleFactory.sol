// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

import {Errors} from "../libraries/helpers/Errors.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IRaffleFactory} from "../interfaces/IRaffleFactory.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";

import {RaffleDataTypes} from "./RaffleDataTypes.sol";
import {Raffle} from "./Raffle.sol";
 
contract RaffleFactory is IRaffleFactory{
    using Clones for address;

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
    function createNewRaffle(Params memory params) external override returns(Raffle newRaffle){
        newRaffle = Raffle(raffleImplementation.clone());
        params.nftContract.transferFrom(msg.sender, address(newRaffle), params.nftId);
        newRaffle.initialize(_convertParams(params));
        isRegisteredRaffle[address(newRaffle)] = true;
        emit NewRaffle(address(newRaffle), params);
    }

    function batchRaffleDrawnTickets(address[] memory _raffleContracts) external override {
        for(uint32 i; i<_raffleContracts.length; ++i){
            Raffle(_raffleContracts[i]).drawnTickets();
        }
    }

    //----------------------------------------
    // Internal functions
    //----------------------------------------
    function _convertParams(Params memory params) internal view returns(RaffleDataTypes.InitRaffleParams memory raffleParams){
        raffleParams = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            params.purchaseCurrency,
            params.nftContract,
            msg.sender,
            params.nftId,
            params.maxTicketSupply,
            params.ticketPrice,
            params.ticketSaleDuration
        );
    }

}
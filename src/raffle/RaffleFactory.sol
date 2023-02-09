// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IRaffle} from "../interfaces/IRaffle.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";

import {RaffleDataTypes} from "./RaffleDataTypes.sol";
import {Raffle} from "./Raffle.sol";
 
contract RaffleFactory {
    using Clones for address;

    //----------------------------------------
    // Storage
    //----------------------------------------
    struct Params {
        IERC20 purchaseCurrency;
        IERC721 nftContract;
        uint256 nftId;
        uint256 maxTicketSupply;
        uint256 ticketPrice;
        uint64 openTicketSaleDuration;
    }

    IImplementationManager immutable implementationManager;
    address immutable raffleImplementation;

    //----------------------------------------
    // Events
    //----------------------------------------
    event NewRaffle(address indexed raffleContract, Params globalData);

    //----------------------------------------
    // Constructor
    //----------------------------------------
    constructor(address _implementationManager){
        implementationManager = IImplementationManager(_implementationManager);
        raffleImplementation  = address(new Raffle());
    }

    //----------------------------------------
    // External functions
    //----------------------------------------
    function createNewRaffle(Params memory _params) external {
        address newRaffle = raffleImplementation.clone();
        IRaffle(newRaffle).initialize(_convertParams(_params));
        emit NewRaffle(newRaffle, _params);
    }

    //----------------------------------------
    // Internal functions
    //----------------------------------------
    function _convertParams(Params memory _params) internal view returns(RaffleDataTypes.InitRaffleParams memory raffleParams){
        raffleParams = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            _params.purchaseCurrency,
            _params.nftContract,
            msg.sender,
            _params.nftId,
            _params.maxTicketSupply,
            _params.ticketPrice,
            _params.openTicketSaleDuration
        );
    }

}
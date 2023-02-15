// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

import {Errors} from "../libraries/helpers/Errors.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
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
    // Modifier
    //----------------------------------------

    modifier onlyRamdomProvider() {
        if(randomProvider() != msg.sender) revert Errors.NOT_RANDOM_PROVIDER_CONTRACT();
        _;
    }

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
    function createNewRaffle(Params memory _params) external override returns(Raffle newRaffle){
        newRaffle = Raffle(raffleImplementation.clone());
        _params.nftContract.transferFrom(msg.sender, address(newRaffle), _params.nftId);
        newRaffle.initialize(_convertParams(_params));
        isRegisteredRaffle[address(newRaffle)] = true;
        emit NewRaffle(address(newRaffle), _params);
    }

    function drawnMultiRaffleTickets(address[] memory _raffleContracts) external override {
        for(uint32 i; i<_raffleContracts.length; ++i){
            Raffle(_raffleContracts[i]).drawnTickets();
        }
    }
    
    /**
    * @notice get the randomProvider contract address from the implementationManager
    * @return The address of the randomProvider contract
    */
    function randomProvider() public view returns(address){
        return implementationManager.getImplementationAddress(ImplementationInterfaceNames.RandomProvider);
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
            _params.ticketSaleDuration
        );
    }

}
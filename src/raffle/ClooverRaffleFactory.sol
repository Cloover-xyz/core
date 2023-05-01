// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

import {Errors} from "../libraries/helpers/Errors.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";
import {IConfigManager} from "../interfaces/IConfigManager.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {ClooverRaffleDataTypes} from "../libraries/types/ClooverRaffleDataTypes.sol";
import {InsuranceLogic} from "../libraries/math/InsuranceLogic.sol";

import {ClooverRaffle} from "./ClooverRaffle.sol";
 
contract ClooverRaffleFactory is IClooverRaffleFactory {
    using Clones for address;
    using InsuranceLogic for uint;

    //----------------------------------------
    // Storage
    //----------------------------------------
    IImplementationManager immutable implementationManager;

    address immutable raffleImplementation;

    mapping(address => bool) public override isRegisteredClooverRaffle;
    
    mapping(uint256 => address[]) public requestIdToContracts;

    //----------------------------------------
    // Events
    //----------------------------------------
    event NewClooverRaffle(address indexed raffleContract, Params globalData);

      

    //----------------------------------------
    // Constructor
    //----------------------------------------
    constructor(IImplementationManager _implementationManager){
        implementationManager = _implementationManager;
        raffleImplementation  = address(new ClooverRaffle());
    }

    //----------------------------------------
    // External functions
    //----------------------------------------

    /// @inheritdoc IClooverRaffleFactory
    function createNewClooverRaffle(Params memory params) external override payable returns(ClooverRaffle newClooverRaffle){
        newClooverRaffle = ClooverRaffle(raffleImplementation.clone());
        params.nftContract.transferFrom(msg.sender, address(newClooverRaffle), params.nftId);
        _handleInsurance(params, address(newClooverRaffle));
        newClooverRaffle.initialize{value: msg.value}(_convertParams(params));
        isRegisteredClooverRaffle[address(newClooverRaffle)] = true;
        emit NewClooverRaffle(address(newClooverRaffle), params);
    }

    function batchClooverRaffledraw(address[] memory _raffleContracts) external override {
        for(uint32 i; i<_raffleContracts.length; ++i){
            ClooverRaffle(_raffleContracts[i]).draw();
        }
    }

    function deregisterClooverRaffle() external override{
        isRegisteredClooverRaffle[msg.sender] = false;
    }
    
    //----------------------------------------
    // Internal functions
    //----------------------------------------

    function _handleInsurance(Params memory params, address newClooverRaffle) internal {
        if(params.minTicketSalesInsurance > 0 && !params.isETHTokenSales){
            IConfigManager configManager = IConfigManager(
                implementationManager.getImplementationAddress(
                    ImplementationInterfaceNames.ConfigManager
                )
            );
            uint256 insuranceCost = params.minTicketSalesInsurance.calculateInsuranceCost(params.ticketPrice,  configManager.insuranceSalesPercentage());
            params.purchaseCurrency.transferFrom(msg.sender, newClooverRaffle, insuranceCost);
        }
    }
    
    function _convertParams(Params memory params) internal view returns(ClooverRaffleDataTypes.InitClooverRaffleParams memory raffleParams){
        raffleParams = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            params.maxTicketAllowedToPurchase,
            params.royaltiesPercentage
        );
    }

    function version() external pure override returns(string memory){
        return "1";
    }
}
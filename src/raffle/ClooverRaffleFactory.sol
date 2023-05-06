// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Clones} from "openzeppelin-contracts/contracts/proxy/Clones.sol";

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
    event NewRaffle(address indexed raffleContract, ClooverRaffleDataTypes.CreateRaffleParams params);

      

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
    function createNewRaffle(ClooverRaffleDataTypes.CreateRaffleParams memory params) external override payable returns(ClooverRaffle newRaffle){
        newRaffle = ClooverRaffle(raffleImplementation.clone());
        params.nftContract.transferFrom(msg.sender, address(newRaffle), params.nftId);
        _handleInsurance(params, address(newRaffle));
        newRaffle.initialize{value: msg.value}(_convertParams(params));
        isRegisteredClooverRaffle[address(newRaffle)] = true;
        emit NewRaffle(address(newRaffle), params);
    }

    /// @inheritdoc IClooverRaffleFactory
    function batchClooverRaffledraw(address[] memory _raffleContracts) external override {
        for(uint32 i; i<_raffleContracts.length; ++i){
            ClooverRaffle(_raffleContracts[i]).draw();
        }
    }
    
    /// @inheritdoc IClooverRaffleFactory
    function deregisterClooverRaffle() external override{
        isRegisteredClooverRaffle[msg.sender] = false;
    }
    
    //----------------------------------------
    // Internal functions
    //----------------------------------------

    function _handleInsurance(ClooverRaffleDataTypes.CreateRaffleParams memory params, address newRaffle) internal {
        uint256 _ticketSalesInsurance = params.ticketSalesInsurance;
        if(_ticketSalesInsurance > 0 && address(params.purchaseCurrency) != address(0)){
            IConfigManager configManager = IConfigManager(
                implementationManager.getImplementationAddress(
                    ImplementationInterfaceNames.ConfigManager
                )
            );
            uint256 insuranceCost = _ticketSalesInsurance.calculateInsuranceCost(params.ticketPrice,  configManager.insuranceRate());
            params.purchaseCurrency.transferFrom(msg.sender, newRaffle, insuranceCost);
        }
    }
    
    function _convertParams(ClooverRaffleDataTypes.CreateRaffleParams memory params) internal view returns(ClooverRaffleDataTypes.InitializeRaffleParams memory raffleParams){
        raffleParams = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:msg.sender,
            implementationManager: implementationManager,
            purchaseCurrency: params.purchaseCurrency,
            nftContract: params.nftContract,
            nftId: params.nftId,
            ticketPrice: params.ticketPrice,
            ticketSalesDuration: params.ticketSalesDuration,
            maxTotalSupply: params.maxTotalSupply,
            maxTicketAllowedToPurchase: params.maxTicketAllowedToPurchase,
            ticketSalesInsurance: params.ticketSalesInsurance,
            royaltiesRate: params.royaltiesRate
        });
    }

    function version() external pure override returns(string memory){
        return "1";
    }
}
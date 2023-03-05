
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IConfigManager} from "../interfaces/IConfigManager.sol";


import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ConfiguratorInputTypes} from "../libraries/types/ConfiguratorInputTypes.sol";

contract ConfigManager is IConfigManager {
    using PercentageMath for uint256;

    struct RaffleConfigData{
        uint256 protocolFeesPercentage;
        uint256 maxTicketSupplyAllowed;
        uint256 minTicketSalesDuration;
        uint256 maxTicketSalesDuration;
        uint256 insuranceSalesPercentage;
    }
    
    //----------------------------------------
    // Storage
    //----------------------------------------

    IImplementationManager public _implementationManager;

    RaffleConfigData private _raffleConfigData;

    //----------------------------------------
    // Events
    //----------------------------------------

    event ProtocolFeesPercentageUpdated(uint256 newFeePercentage);
    event MaxTicketSupplyAllowedUpdated(uint256 newMaxTicketSupplyAllowed);
    event MinTicketSalesDurationUpdated(uint256 newMinTicketSalesDuration);
    event MaxTicketSalesDurationUpdated(uint256 newMaxTicketSalesDuration);
    event InsuranceSalesPercentageUpdated(uint256 newInsuranceSalesPercentage);

    //----------------------------------------
    // Modifiers
    //----------------------------------------
    modifier onlyMaintainer() {
        IAccessController accessController = IAccessController(_implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController));
        if(!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    }

    //----------------------------------------
    // Initialization function
    //----------------------------------------
    constructor(IImplementationManager implManager, ConfiguratorInputTypes.InitConfigManagerInput memory _data){
        if(_data.protocolFeesPercentage > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if(_data.insuranceSalesPercentage > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if(_data.minTicketSalesDuration > _data.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        if(_data.maxTicketSupplyAllowed == 0) revert Errors.CANT_BE_ZERO();
        _implementationManager = implManager;
        _raffleConfigData = RaffleConfigData(
            _data.protocolFeesPercentage,
            _data.maxTicketSupplyAllowed,
            _data.minTicketSalesDuration,
            _data.maxTicketSalesDuration, 
            _data.insuranceSalesPercentage
        );
    }

    //----------------------------------------
    // External function
    //----------------------------------------

    function setProcolFeesPercentage(uint256 newFeePercentage) external onlyMaintainer{
        if(newFeePercentage > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _raffleConfigData.protocolFeesPercentage = newFeePercentage;
        emit ProtocolFeesPercentageUpdated(newFeePercentage);
    }

    function procolFeesPercentage() external view override returns(uint256) {
        return _raffleConfigData.protocolFeesPercentage;
    }
    
    function setInsuranceSalesPercentage(uint256 newInsuranceSalesPercentage) external onlyMaintainer{
        if(newInsuranceSalesPercentage > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _raffleConfigData.insuranceSalesPercentage = newInsuranceSalesPercentage;
        emit InsuranceSalesPercentageUpdated(newInsuranceSalesPercentage);
    }

    function insuranceSalesPercentage() external view override returns(uint256) {
        return _raffleConfigData.insuranceSalesPercentage;
    }

    function setMinTicketSalesDuration(uint256 newMinTicketSalesDuration) external onlyMaintainer{
        if(newMinTicketSalesDuration > _raffleConfigData.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        _raffleConfigData.minTicketSalesDuration = newMinTicketSalesDuration;
        emit MinTicketSalesDurationUpdated(newMinTicketSalesDuration);
    }

    function minTicketSalesDuration() external view override returns(uint256) {
        return _raffleConfigData.minTicketSalesDuration;
    }

    function setMaxTicketSalesDuration(uint256 newMaxTicketSalesDuration) external onlyMaintainer{
        if(newMaxTicketSalesDuration < _raffleConfigData.minTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        _raffleConfigData.maxTicketSalesDuration = newMaxTicketSalesDuration;
        emit MaxTicketSalesDurationUpdated(newMaxTicketSalesDuration);
    }

    function maxTicketSalesDuration() external view override returns(uint256) {
        return _raffleConfigData.maxTicketSalesDuration;
    }

    function setMaxTicketSupplyAllowed(uint256 newMaxTicketSupplyAllowed) external onlyMaintainer{
        _raffleConfigData.maxTicketSupplyAllowed = newMaxTicketSupplyAllowed;
        emit MaxTicketSupplyAllowedUpdated(newMaxTicketSupplyAllowed);
    }

    function maxTicketSupplyAllowed() external view override returns(uint256) {
        return _raffleConfigData.maxTicketSupplyAllowed;
    }

    function implementationManager() external view returns(IImplementationManager) {
        return _implementationManager;
    }

    function ticketSalesDurationLimits() external view returns(uint256 minDuration, uint256 maxDuration){
        return (_raffleConfigData.minTicketSalesDuration,_raffleConfigData.maxTicketSalesDuration);
    }
}
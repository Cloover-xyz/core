
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IConfigManager} from "../interfaces/IConfigManager.sol";


import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";
import {ConfigManagerDataTypes} from "../libraries/types/ConfigManagerDataTypes.sol";

contract ConfigManager is IConfigManager {

    using PercentageMath for uint256;
   
    //----------------------------------------
    // Storage
    //----------------------------------------

    IImplementationManager public _implementationManager;

    ConfigManagerDataTypes.ProtocolConfigData private _config;

    //----------------------------------------
    // Events
    //----------------------------------------

    event ProtocolFeeRateUpdated(uint256 newFeeRate);
    event MaxTotalSupplyAllowedUpdated(uint256 newMaxTicketSupply);
    event MinTicketSalesDurationUpdated(uint256 newMinTicketSalesDuration);
    event MaxTicketSalesDurationUpdated(uint256 newMaxTicketSalesDuration);
    event InsuranceRateUpdated(uint256 newinsuranceRate);

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
    constructor(IImplementationManager implManager, ConfigManagerDataTypes.InitConfigManagerParams memory _data){
        if(_data.protocolFeeRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if(_data.insuranceRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        if(_data.minTicketSalesDuration > _data.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        if(_data.maxTotalSupplyAllowed == 0) revert Errors.CANT_BE_ZERO();
        _implementationManager = implManager;
        _config = ConfigManagerDataTypes.ProtocolConfigData({
            maxTotalSupplyAllowed:_data.maxTotalSupplyAllowed,
            protocolFeeRate: _data.protocolFeeRate,
            insuranceRate: _data.insuranceRate,
            minTicketSalesDuration: _data.minTicketSalesDuration,
            maxTicketSalesDuration: _data.maxTicketSalesDuration
        });
    }

    //----------------------------------------
    // External function
    //----------------------------------------

    function setProtocolFeeRate(uint16 newFeeRate) external onlyMaintainer {
        if(newFeeRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _config.protocolFeeRate = newFeeRate;
        emit ProtocolFeeRateUpdated(newFeeRate);
    }

    function protocolFeeRate() external view override returns(uint256) {
        return _config.protocolFeeRate;
    }
    
    function setInsuranceRate(uint16 newinsuranceRate) external onlyMaintainer {
        if(newinsuranceRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _config.insuranceRate = newinsuranceRate;
        emit InsuranceRateUpdated(newinsuranceRate);
    }

    function insuranceRate() external view override returns(uint256) {
        return _config.insuranceRate;
    }

    function setMinTicketSalesDuration(uint64 newMinTicketSalesDuration) external onlyMaintainer {
        if(newMinTicketSalesDuration > _config.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        _config.minTicketSalesDuration = newMinTicketSalesDuration;
        emit MinTicketSalesDurationUpdated(newMinTicketSalesDuration);
    }

    function minTicketSalesDuration() external view override returns(uint256) {
        return _config.minTicketSalesDuration;
    }

    function setMaxTicketSalesDuration(uint64 newMaxTicketSalesDuration) external onlyMaintainer {
        if(newMaxTicketSalesDuration < _config.minTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        _config.maxTicketSalesDuration = newMaxTicketSalesDuration;
        emit MaxTicketSalesDurationUpdated(newMaxTicketSalesDuration);
    }

    function maxTicketSalesDuration() external view override returns(uint256) {
        return _config.maxTicketSalesDuration;
    }

    function setMaxTotalSupplyAllowed(uint16 newMaxTotalSupplyAllowed) external onlyMaintainer {
        _config.maxTotalSupplyAllowed = newMaxTotalSupplyAllowed;
        emit MaxTotalSupplyAllowedUpdated(newMaxTotalSupplyAllowed);
    }

    function maxTotalSupplyAllowed() external view override returns(uint256) {
        return _config.maxTotalSupplyAllowed;
    }

    function implementationManager() external view returns(IImplementationManager) {
        return _implementationManager;
    }

    function ticketSalesDurationLimits() external view returns(uint256 minDuration, uint256 maxDuration) {
        return (_config.minTicketSalesDuration,_config.maxTicketSalesDuration);
    }
}
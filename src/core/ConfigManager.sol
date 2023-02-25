
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IConfigManager} from "../interfaces/IConfigManager.sol";


import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {PercentageMath} from "../libraries/math/PercentageMath.sol";

contract ConfigManager is IConfigManager{
    using PercentageMath for uint256;
    
    //----------------------------------------
    // Storage
    //----------------------------------------

    IImplementationManager public _implementationManager;

    uint256 private _protocolFeesPercentage;

    //----------------------------------------
    // Events
    //----------------------------------------

    event UpdateProtocolFeesPercentage(uint256 newFeePercentage);

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
    constructor(IImplementationManager implManager, uint256 baseFeePercentage){
        if(baseFeePercentage > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _implementationManager = implManager;
        _protocolFeesPercentage = baseFeePercentage;
    }

    //----------------------------------------
    // External function
    //----------------------------------------


    function setProcolFeesPercentage(uint256 newFeePercentage) external override onlyMaintainer{
        if(newFeePercentage > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _protocolFeesPercentage = newFeePercentage;
        emit UpdateProtocolFeesPercentage(newFeePercentage);
    }

    function procolFeesPercentage() external view override returns(uint256 feesPercentage) {
        return _protocolFeesPercentage;
    }


    function implementationManager() external view returns(IImplementationManager) {
        return _implementationManager;
    }
}
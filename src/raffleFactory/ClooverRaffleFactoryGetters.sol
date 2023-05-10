// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IClooverRaffleFactoryGetters} from "../interfaces/IClooverRaffleFactory.sol";

import {ClooverRaffleFactoryInternal} from "./ClooverRaffleFactoryInternal.sol";

abstract contract ClooverRaffleFactoryGetters is IClooverRaffleFactoryGetters, ClooverRaffleFactoryInternal {
    using EnumerableSet for EnumerableSet.AddressSet;
    /// @inheritdoc IClooverRaffleFactoryGetters
    function protocolFeeRate() external view override returns(uint256) {
        return _config.protocolFeeRate;
    }
    
    /// @inheritdoc IClooverRaffleFactoryGetters
    function insuranceRate() external view override returns(uint256) {
        return _config.insuranceRate;
    }
    
    /// @inheritdoc IClooverRaffleFactoryGetters
    function minTicketSalesDuration() external view override returns(uint256) {
        return _config.minTicketSalesDuration;
    }
    
    /// @inheritdoc IClooverRaffleFactoryGetters
    function maxTicketSalesDuration() external view override returns(uint256) {
        return _config.maxTicketSalesDuration;
    }
    
    /// @inheritdoc IClooverRaffleFactoryGetters
    function maxTotalSupplyAllowed() external view override returns(uint256) {
        return _config.maxTotalSupplyAllowed;
    }
    
    /// @inheritdoc IClooverRaffleFactoryGetters
    function implementationManager() external view returns(IImplementationManager) {
        return _implementationManager;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function ticketSalesDurationLimits() external view returns(uint256 minDuration, uint256 maxDuration) {
        return (_config.minTicketSalesDuration,_config.maxTicketSalesDuration);
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function isRegistered(address raffle)
    external
    view
    override
    returns (bool)
    {
        return _registeredRaffles.contains(raffle);
    }

   
    /// @inheritdoc IClooverRaffleFactoryGetters
    function getRegisteredRaffle() external view returns (address[] memory) {
        uint256 numberOfElements = _registeredRaffles.length();
        address[] memory activeNftCollections = new address[](numberOfElements);
        for (uint256 i = 0; i < numberOfElements; ++i) {
            activeNftCollections[i] = _registeredRaffles.at(i);
        }
        return activeNftCollections;
    }

    /// @inheritdoc IClooverRaffleFactoryGetters
    function version() external pure override returns(string memory){
        return "1";
    }
}
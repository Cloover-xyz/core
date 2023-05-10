// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ClooverRaffleTypes} from "../libraries/ClooverRaffleTypes.sol";

import {ClooverRaffle} from "../raffle/ClooverRaffle.sol";

abstract contract ClooverRaffleFactoryStorage {

    /// @notice The implementationManager contract
    IImplementationManager internal _implementationManager;

    /// @notice The raffle implementation contract address
    address internal _raffleImplementation;

    /// @notice Map of registered raffle
    EnumerableSet.AddressSet internal _registeredRaffles;

    /// @notice The global config and limits for raffles
    ClooverRaffleTypes.FactoryConfig internal _config;
    
}
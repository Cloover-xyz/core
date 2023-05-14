// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {ClooverRaffleTypes} from "../libraries/Types.sol";

/// @title ClooverRaffleFactoryStorage
/// @author Cloover
/// @notice The storage shared by ClooverRaffleFactory's contracts.
abstract contract ClooverRaffleFactoryStorage {
    uint256 internal constant MIN_TICKET_PRICE = 10000;

    /// @notice The implementationManager contract
    address internal _implementationManager;

    /// @notice The raffle implementation contract address
    address internal _raffleImplementation;

    /// @notice Map of registered raffle
    EnumerableSet.AddressSet internal _registeredRaffles;

    /// @notice The global config and limits for raffles
    ClooverRaffleTypes.FactoryConfig internal _config;
}

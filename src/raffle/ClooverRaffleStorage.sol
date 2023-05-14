// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {ClooverRaffleTypes} from "../libraries/ClooverRaffleTypes.sol";

/// @title ClooverRaffleStorage
/// @author Cloover
/// @notice The storage shared by ClooverRaffle's contracts.
abstract contract ClooverRaffleStorage is Initializable {
    /// @dev the raffle config data
    ClooverRaffleTypes.ConfigData internal _config;

    /// @dev The life cycle data of the raffle
    ClooverRaffleTypes.LifeCycleData internal _lifeCycleData;

    /// @dev The list of entries purchased by participants
    ClooverRaffleTypes.PurchasedEntries[] internal _purchasedEntries;

    /// @dev Map of participant address to their purchase info
    mapping(address => ClooverRaffleTypes.ParticipantInfo) internal _participantInfoMap;

    //----------------------------------------
    // Constructor
    //----------------------------------------
    /// @notice Contract constructor.
    /// @dev The implementation contract disables initialization upon deployment to avoid being hijacked.
    constructor() {
        _disableInitializers();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleDataTypes} from "../libraries/types/ClooverRaffleDataTypes.sol";

abstract contract ClooverRaffleStorage {

    ClooverRaffleDataTypes.PurchasedEntries[] internal _purchasedEntries;

    // Mapping owner address to PurchasedEntries index
    mapping(address => ClooverRaffleDataTypes.ParticipantInfo) internal _participantInfoMap;

    ClooverRaffleDataTypes.ConfigData internal _config;

    ClooverRaffleDataTypes.LifeCycleData internal _lifeCycleData;
}
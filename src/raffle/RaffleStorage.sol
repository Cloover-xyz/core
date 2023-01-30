// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {RaffleDataTypes} from './RaffleDataTypes.sol';

/**
 * @title RaffleStorage
 * @notice Contract used as storage of the Raffle contract.
 * @dev It defines the storage layout of the Raffle contract.
 */
contract RaffleStorage {

    // Mapping from ticket ID to owner address
    mapping(uint256 => address) internal _ticketOwner;

    // Mapping owner address to tickets list
    mapping(address => uint256[]) internal _ownerTickets;

    RaffleDataTypes.RaffleData internal _globalData;
}
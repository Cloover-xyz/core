// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRaffle {

    /**
     * @notice Allow to purchase tickets
     * @param nbOfTickets number of tickets purchased
     */
    function purchaseTicket(uint256 nbOfTickets) external;
}
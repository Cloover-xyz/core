// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRaffle {

    /**
     * @notice Allow to purchase tickets
     * @dev Only accessible if raffle still open to particpants
     * @param nbOfTickets number of tickets purchased
     */
    function purchaseTicket(uint256 nbOfTickets) external;

    /**
     * @notice Allow winner to claim his price
     * @dev Ticket number must be draw and raffle close to new participants
     */
    function claimPrice() external;
}
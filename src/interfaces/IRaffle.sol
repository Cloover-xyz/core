// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRaffle {

    /**
     * @notice Allows users to purchase tickets
     * @dev Only accessible if raffle still open to particpants
     * @param nbOfTickets number of tickets purchased
     */
    function purchaseTickets(uint256 nbOfTickets) external;

    /**
     * @notice Allows the winner to claim his price
     * @dev Ticket number must be draw and raffle close to new participants
     */
    function claimPrice() external;
    
    /**
     * @notice Allows the creator to claim the amount related to the ticket sales
     * @dev The functions should send to the creator his part after fees
     */
    function claimTicketSalesAmount() external;
    
    /**
     * @notice Request a random number
     * @dev must call the RandomProvider that use ChainLinkVRFv2 
     */
    function drawnRandomTicket() external;

    /**
     * @notice Select the winning tickets number received from the RandomProvider contract
     * @dev must be only called by the RandomProvider contract
     * @param randomNumber random number requested
     */
    function drawnTicket(uint256 randomNumber) external;
}
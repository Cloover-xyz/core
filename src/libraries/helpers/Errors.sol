// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts of the protocol
 */
library Errors {
    error BE_ADDRESS_0(); // 'Address must be address(0)'
    error NOT_ADDRESS_0(); // 'Address must not be address(0)'
    error RAFFLE_CLOSE(); // 'Current timestamps greater or equal than the close time'
    error RAFFLE_STILL_OPEN(); // 'Current timestamps lesser or equal than the close time'
    error CANT_BE_ZERO(); // 'Value can't must be higher than 0'
    error MAX_TICKET_SUPPLY_EXCEEDED(); // 'Maximum amount of ticket sold for the raffle has been reached'
    error NOT_ENOUGH_BALANCE(); // 'Balance lower than required'
    error MSG_SENDER_NOT_WINNER(); // 'msg.sender is not winner address'
    error NOT_CREATOR(); // 'msg.sender is not the creator of the raffle'
    error TICKET_NOT_DRAWN(); // 'ticket must be drawn'
    error TICKET_ALREADY_DRAWN(); // 'ticket has already be drawn'
    error TICKET_DRAWN_NOT_REQUESTED(); // 'ticket drawn has not be requested'
    error NOT_MAINTAINER(); // 'Caller is not the maintainer'
    error IMPLEMENTATION_NOT_FOUND(); // 'Implementation interfaces is not registered'
    error NOT_RAFFLE_CONTRACT(); // 'Caller is not a raffle contract'
    error NOT_RANDOM_PROVIDER_CONTRACT(); // 'Caller is not the random provider contract'
    error NOT_NFT_OWNER(); // 'Address not the nft owner'
    error ARRAYS_LENGTH_NOT_EQUAL(); // 'Arrays doesn't have the same size'
    error COLLECTION_ALREADY_WHITELISTED();
    error COLLECTION_NOT_WHITELISTED(); 
    error BELLOW_MIN_DURATION(); 
}

 
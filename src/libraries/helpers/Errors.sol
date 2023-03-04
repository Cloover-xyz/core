// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    error COLLECTION_ALREADY_WHITELISTED(); //'NFT collection already whitelisted'
    error COLLECTION_NOT_WHITELISTED(); //'NFT collection not whitelisted'
    error TOKEN_ALREADY_WHITELISTED(); //'Token already whitelisted'
    error TOKEN_NOT_WHITELISTED(); //'Token not whitelisted'
    error BELLOW_MIN_DURATION(); //'Ticket sales duration must be higher than min defined'
    error ABOVE_MAX_DURATION(); //'Ticket sales duration must be lower than max defined'
    error EXCEED_MAX_PERCENTAGE(); //'Percentage value must be lower than max allowed'
    error EXCEED_MAX_VALUE_ALLOWED(); //'Value must be lower than max allowed'
    error WRONG_DURATION_LIMITS(); //'The min duration must be lower than the max one'
    error OUT_OF_RANGE(); //'The value is not in the allowed range'
}

 
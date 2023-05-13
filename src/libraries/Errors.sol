// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title Errors library
/// @author Cloover
/// @notice Library exposing errors used in Cloover's contracts
library Errors {
    error ADDRESS_0(); // 'Address must be address(0)'
    error NOT_ADDRESS_0(); // 'Address must not be address(0)'
    error CANT_BE_ZERO(); // 'Value can't must be higher than 0'
    error NOT_MAINTAINER(); // 'Caller is not the maintainer'
    error IMPLEMENTATION_NOT_FOUND(); // 'Implementation interfaces is not registered'
    error ARRAYS_LENGTH_NOT_EQUAL(); // 'Arrays doesn't have the same size'
    error ALREADY_WHITELISTED(); //'address already whitelisted'
    error NOT_WHITELISTED(); //'address not whitelisted'
    error BELLOW_MIN_DURATION(); //'Ticket sales duration must be higher than min defined'
    error ABOVE_MAX_DURATION(); //'Ticket sales duration must be lower than max defined'
    error EXCEED_MAX_PERCENTAGE(); //'Percentage value must be lower than max allowed'
    error EXCEED_MAX_VALUE_ALLOWED(); //'Value must be lower than max allowed'
    error WRONG_DURATION_LIMITS(); //'The min duration must be lower than the max one'
    error OUT_OF_RANGE(); //'The value is not in the allowed range'
    error SALES_ALREADY_STARTED(); // 'At least one ticket has already been sold'
    error RAFFLE_CLOSE(); // 'Current timestamps greater or equal than the close time'
    error RAFFLE_STILL_OPEN(); // 'Current timestamps lesser or equal than the close time'
    error DRAW_NOT_POSSIBLE(); // 'Raffle is status forwards than DRAWNING'
    error TICKET_SUPPLY_OVERFLOW(); // 'Maximum amount of ticket sold for the raffle has been reached'
    error WRONG_MSG_VALUE(); // 'msg.value not valid'
    error WRONG_AMOUNT(); // 'msg.value not valid'
    error MSG_SENDER_NOT_WINNER(); // 'msg.sender is not winner address'
    error NOT_CREATOR(); // 'msg.sender is not the creator of the raffle'
    error TICKET_NOT_DRAWN(); // 'ticket must be drawn'
    error TICKET_ALREADY_DRAWN(); // 'ticket has already be drawn'
    error DRAWN_NOT_REQUESTED(); // 'ticket drawn has not be requested'
    error NOT_IN_REFUND_MODE(); // 'raffle is not in insurance mode'
    error IN_REFUND_MODE(); // 'raffle is in insurance mode'
    error NOT_REGISTERED_RAFFLE(); // 'Caller is not a raffle contract registered'
    error NOT_RANDOM_PROVIDER_CONTRACT(); // 'Caller is not the random provider contract'
    error NOT_NFT_OWNER(); // 'Address not the nft owner'
    error COLLECTION_ALREADY_WHITELISTED(); //'NFT collection already whitelisted'
    error COLLECTION_NOT_WHITELISTED(); //'NFT collection not whitelisted'
    error TOKEN_ALREADY_WHITELISTED(); //'Token already whitelisted'
    error TOKEN_NOT_WHITELISTED(); //'Token not whitelisted'
    error IS_ETH_RAFFLE(); //'Ticket can only be purchase with native token (ETH)'
    error NOT_ETH_RAFFLE(); //'Ticket can only be purchase with ERC20 token'
    error NO_INSURANCE_TAKEN(); //'ClooverRaffle's creator didn't took insurance'
    error INSURANCE_AMOUNT(); //'Insurance cost must paid'
    error SALES_EXCEED_INSURANCE_LIMIT(); //'Ticket sales exceed min ticket sales covered by the insurance'
    error ALREADY_CLAIMED(); //'User already claimed his part'
    error NOTHING_TO_CLAIM(); //'User has nothing to claim'
    error EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE(); //'User exceed allowed ticket to purchase limit'
}

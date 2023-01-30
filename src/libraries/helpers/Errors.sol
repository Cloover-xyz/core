// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Errors library
 * @notice Defines the error messages emitted by the different contracts of the protocol
 */
library Errors {
    error BE_ADDRESS_0(); // 'Address must be address(0)'
    error NOT_ADDRESS_0(); // 'Address must not be address(0)'
    error TIME_EXCEEDED(); // 'Current timestamps greater or equal than the value required'
    error TIME_NOT_EXCEEDED(); // 'Current timestamps lesser or equal than the value required'
    error CANT_BE_ZERO(); // 'Value can't must be higher than 0'
    error MAX_TICKET_SUPPLY_EXCEEDED(); // 'Maximum amount of ticket sold for the raffle has been reached'
    error NOT_ENOUGH_BALANCE(); // 'Balance lower than required'
    error MSG_SENDER_NOT_WINNER(); // 'msg.sender is not winner address'
}

 
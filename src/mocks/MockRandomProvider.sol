// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IRandomProvider} from "@interfaces/IRandomProvider.sol";
import {IRaffle} from "@interfaces/IRaffle.sol";

contract MockRandomProvider is IRandomProvider {

    IRaffle raffle;

    constructor(IRaffle _raffle){
        raffle = _raffle;
    }

    function requestRandomNumber() external{
        uint256 randomNumber = uint256(blockhash(block.number - 1));
        raffle.drawnTicket(randomNumber);
    }

    function requestRandomNumberReturnZero() external{
        raffle.drawnTicket(0);
    }
}
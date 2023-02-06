// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {IRaffle} from "../interfaces/IRaffle.sol";

contract MockRandomProvider is IRandomProvider {

    IRaffle raffle;

    constructor(IRaffle _raffle){
        raffle = _raffle;
    }

    function requestRandomNumbers(uint32 numWords) external override {
        uint256[] memory randomNumbers = new uint256[](numWords);
        for(uint256 i;i<numWords;i++){
            if(i ==0){
                 randomNumbers[i] = uint256(keccak256(abi.encode(blockhash(block.number - 1), msg.sender)));
            } else {
                randomNumbers[i] =  uint256(keccak256(abi.encode(randomNumbers[i-1], blockhash(block.number - 1))));
            }
        }
        
        raffle.drawnTickets(randomNumbers);
    }

    function requestRandomNumberReturnZero() external{
        uint256[] memory zero = new uint256[](1);
        zero[0] = 0;
        raffle.drawnTickets(zero);
    }
}
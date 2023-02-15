// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IRaffleFactory} from "../interfaces/IRaffleFactory.sol";
import {IRaffle} from "../interfaces/IRaffle.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";

contract MockRandomProvider is IRandomProvider {

    IImplementationManager public implementationManager;

    
    mapping(address => uint256) public callerToRequestId;
    mapping(uint256 => address) public requestIdToCaller;
    mapping(uint256 => uint256) public requestIdToNumWords;
    
    uint256 nonce;

    constructor(IImplementationManager _implementationManager){
        implementationManager = _implementationManager;
    }
 
    function requestRandomNumbers(uint32 numWords) external override returns(uint256 requestId){
        requestId = uint256(keccak256(abi.encode(blockhash(block.number - 1), msg.sender, nonce)));
        callerToRequestId[msg.sender] = requestId;
        requestIdToCaller[requestId] = msg.sender;
        requestIdToNumWords[requestId] = numWords;
        nonce = requestId;
    }

    function generateRandomNumbers(uint256 requestId) external {
        uint256 numWordsRequested = requestIdToNumWords[requestId];
        uint256[] memory randomNumbers = new uint256[](numWordsRequested);
        for(uint256 i;i<numWordsRequested;i++){
            if(i ==0){
                 randomNumbers[i] = uint256(keccak256(abi.encode(blockhash(block.number - 1), msg.sender)));
            } else {
                randomNumbers[i] =  uint256(keccak256(abi.encode(randomNumbers[i-1], blockhash(block.number - 1))));
            }
        }
        address requestorAddress = requestIdToCaller[requestId];
        IRaffle(requestorAddress).drawnTickets(randomNumbers); 
    }

    function requestRandomNumberReturnZero(uint256 requestId) external {
        address requestorAddress = requestIdToCaller[requestId];
        uint256 numWordsRequested = requestIdToNumWords[requestId];
        uint256[] memory zeroNumbers = new uint256[](numWordsRequested);
        for(uint256 i;i<numWordsRequested;i++){
            zeroNumbers[i] = 0;
        }
        IRaffle(requestorAddress).drawnTickets(zeroNumbers); 
    }
}
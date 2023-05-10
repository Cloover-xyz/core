// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IImplementationManager} from "src/interfaces/IImplementationManager.sol";
import {IClooverRaffleFactory} from "src/interfaces/IClooverRaffleFactory.sol";
import {IClooverRaffle} from "src/interfaces/IClooverRaffle.sol";
import {IRandomProvider} from "src/interfaces/IRandomProvider.sol";

import {ImplementationInterfaceNames} from "src/libraries/ImplementationInterfaceNames.sol";

contract RandomProviderMock is IRandomProvider {

    IImplementationManager private _implementationManager;

    mapping(address => uint256) public callerToRequestId;
    mapping(uint256 => address) private _requestIdToCaller;
    mapping(uint256 => uint256) public requestIdToNumWords;
    ChainlinkVRFData private _chainlinkVRFData;
    uint256 nonce;

    constructor(IImplementationManager implementationManager_){
        _implementationManager = implementationManager_;
    }
 
    function requestRandomNumbers(uint32 numWords) external override returns(uint256 requestId){
        requestId = uint256(keccak256(abi.encode(blockhash(block.number - 1), msg.sender, nonce)));
        callerToRequestId[msg.sender] = requestId;
        _requestIdToCaller[requestId] = msg.sender;
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
        address requestorAddress = _requestIdToCaller[requestId];
        IClooverRaffle(requestorAddress).draw(randomNumbers); 
    }

    function requestRandomNumberReturnZero(uint256 requestId) external {
        address requestorAddress = _requestIdToCaller[requestId];
        uint256 numWordsRequested = requestIdToNumWords[requestId];
        uint256[] memory zeroNumbers = new uint256[](numWordsRequested);
        for(uint256 i;i<numWordsRequested;i++){
            zeroNumbers[i] = 0;
        }
        IClooverRaffle(requestorAddress).draw(zeroNumbers); 
    }

       
    /// @inheritdoc IRandomProvider
    function clooverRaffleFactory() external view override returns(address){
       return _implementationManager.getImplementationAddress(ImplementationInterfaceNames.ClooverRaffleFactory);
    }

    /// @inheritdoc IRandomProvider
    function implementationManager() external view override returns(IImplementationManager){
        return _implementationManager;
    }

    /// @inheritdoc IRandomProvider
    function requestorAddressFromRequestId(uint256 requestId) external view override returns(address){
        return _requestIdToCaller[requestId];
    }

    /// @inheritdoc IRandomProvider
    function chainlinkVRFData() external view override returns(ChainlinkVRFData memory){
        return _chainlinkVRFData;
    }

}
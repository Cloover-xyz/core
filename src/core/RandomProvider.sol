// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {VRFCoordinatorV2Interface } from "@chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/v0.8/VRFConsumerBaseV2.sol";

import {IImplementationManager} from "@interfaces/IImplementationManager.sol";
import {IAccessController} from "@interfaces/IAccessController.sol";
import {IRandomProvider} from "@interfaces/IRandomProvider.sol";
import {IRaffle} from "@interfaces/IRaffle.sol";

import {ImplementationInterfaceNames} from "@libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "@libraries/helpers/Errors.sol";

contract RandomProvider is VRFConsumerBaseV2, IRandomProvider {

    struct ChainlinkVRFData{
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        address vrfCoordinator;
        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        bytes32 keyHash;
        // A reasonable default is 100000, but this value could be different
        // on other networks.
        uint32 callbackGasLimit;
        // The default is 3, but you can set this higher.
        uint16 requestConfirmations;
        
        uint64 subscriptionId;
    }
    
    //----------------------------------------
    // Storage
    //----------------------------------------

    VRFCoordinatorV2Interface public COORDINATOR;
    
    IImplementationManager public implementationManager;

    ChainlinkVRFData public chainlinkVRFData;

    mapping(uint256 => address) public requestIdToAddress;

    //----------------------------------------
    // Modifier
    //----------------------------------------

    modifier onlyMaintainer() {
        IAccessController accessController = IAccessController(implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController));
        if(!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    } 

    modifier onlyRaffleContract(){
        if(implementationManager.getImplementationAddress(ImplementationInterfaceNames.RaffleContract) != msg.sender) revert Errors.NOT_RAFFLE_CONTRACT();
        _;
    }

   constructor(
        IImplementationManager _implementationManager,
        ChainlinkVRFData memory _data
    )
        VRFConsumerBaseV2(_data.vrfCoordinator)
    {
        implementationManager = _implementationManager;
        COORDINATOR = VRFCoordinatorV2Interface(
            _data.vrfCoordinator
        );
        chainlinkVRFData = _data;
    }

    function requestRandomNumber() external override onlyRaffleContract() {
        uint256 requestId = COORDINATOR.requestRandomWords(
            chainlinkVRFData.keyHash,
            chainlinkVRFData.subscriptionId,
            chainlinkVRFData.requestConfirmations,
            chainlinkVRFData.callbackGasLimit,
            1
        );
        requestIdToAddress[requestId] = msg.sender;
    }

    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        IRaffle(requestIdToAddress[requestId]).drawnTicket(randomWords[0]); 
    }
}
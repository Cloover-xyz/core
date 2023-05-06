// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface } from "chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IAccessController} from "../interfaces/IAccessController.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {IClooverRaffle} from "../interfaces/IClooverRaffle.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

contract RandomProvider is VRFConsumerBaseV2, IRandomProvider {

    struct ChainlinkVRFData {
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

    mapping(uint256 => address) public requestIdToCaller;

    //----------------------------------------
    // Modifier
    //----------------------------------------

    modifier onlyClooverRaffleContract(){
        if(!IClooverRaffleFactory(getClooverRaffleFactory()).isRegisteredClooverRaffle(msg.sender)) revert Errors.NOT_REGISTERED_RAFFLE();
        _;
    }

    //----------------------------------------
    // Initialization 
    //----------------------------------------

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


    //----------------------------------------
    // External functions 
    //----------------------------------------

    /// @inheritdoc IRandomProvider
    function requestRandomNumbers(uint32 numWords) external override onlyClooverRaffleContract() returns(uint256 requestId){
        requestId = COORDINATOR.requestRandomWords(
            chainlinkVRFData.keyHash,
            chainlinkVRFData.subscriptionId,
            chainlinkVRFData.requestConfirmations,
            chainlinkVRFData.callbackGasLimit,
            numWords
        );
        requestIdToCaller[requestId] = msg.sender;
    }

    /**
    * @notice get the randomProvider contract address from the implementationManager
    * @return The address of the randomProvider contract
    */
    function getClooverRaffleFactory() public view returns(address){
       return implementationManager.getImplementationAddress(ImplementationInterfaceNames.ClooverRaffleFactory);
    }

    //----------------------------------------
    // Internal functions 
    //----------------------------------------


    /**
    * @notice internal function call by the ChainLink VRFConsumerBaseV2 fallback
    * @dev only callable by the vrfCoordinator (cf.VRFConsumerBaseV2 and ChainLinkVRFv2 docs)
    */
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        address requestorAddress = requestIdToCaller[requestId];
        IClooverRaffle(requestorAddress).draw(randomWords); 
    }


}
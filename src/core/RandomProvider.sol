// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {VRFCoordinatorV2Interface} from "@chainlink/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/v0.8/vrf/VRFConsumerBaseV2.sol";

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IAccessController} from "../interfaces/IAccessController.sol";
import {IRandomProvider} from "../interfaces/IRandomProvider.sol";
import {IClooverRaffle} from "../interfaces/IClooverRaffle.sol";
import {IClooverRaffleFactory} from "../interfaces/IClooverRaffleFactory.sol";

import {RandomProviderTypes} from "../libraries/Types.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title RandomProvider
/// @author Cloover
/// @notice Contract that manage the link with the ChainLink VRF
contract RandomProvider is VRFConsumerBaseV2, IRandomProvider {
    //----------------------------------------
    // Storage
    //----------------------------------------

    VRFCoordinatorV2Interface public COORDINATOR;

    address private _implementationManager;

    RandomProviderTypes.ChainlinkVRFData private _chainlinkVRFData;

    mapping(uint256 => address) private _requestIdToCaller;

    //----------------------------------------
    // Initialization
    //----------------------------------------

    constructor(address implementationManager_, RandomProviderTypes.ChainlinkVRFData memory data)
        VRFConsumerBaseV2(data.vrfCoordinator)
    {
        _implementationManager = implementationManager_;
        COORDINATOR = VRFCoordinatorV2Interface(data.vrfCoordinator);
        _chainlinkVRFData = data;
    }

    //----------------------------------------
    // External functions
    //----------------------------------------

    /// @inheritdoc IRandomProvider
    function requestRandomNumbers(uint32 numWords) external override returns (uint256 requestId) {
        IClooverRaffleFactory raffleFactory = IClooverRaffleFactory(
            IImplementationManager(_implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.ClooverRaffleFactory
            )
        );
        if (!raffleFactory.isRegistered(msg.sender)) revert Errors.NOT_REGISTERED_RAFFLE();
        requestId = COORDINATOR.requestRandomWords(
            _chainlinkVRFData.keyHash,
            _chainlinkVRFData.subscriptionId,
            _chainlinkVRFData.requestConfirmations,
            _chainlinkVRFData.callbackGasLimit,
            numWords
        );
        _requestIdToCaller[requestId] = msg.sender;
    }

    /// @inheritdoc IRandomProvider
    function clooverRaffleFactory() external view override returns (address) {
        return IImplementationManager(_implementationManager).getImplementationAddress(
            ImplementationInterfaceNames.ClooverRaffleFactory
        );
    }

    /// @inheritdoc IRandomProvider
    function implementationManager() external view override returns (address) {
        return _implementationManager;
    }

    /// @inheritdoc IRandomProvider
    function requestorAddressFromRequestId(uint256 requestId) external view override returns (address) {
        return _requestIdToCaller[requestId];
    }

    /// @inheritdoc IRandomProvider
    function chainlinkVRFData() external view override returns (RandomProviderTypes.ChainlinkVRFData memory) {
        return _chainlinkVRFData;
    }

    //----------------------------------------
    // Internal functions
    //----------------------------------------

    /// @notice internal function call by the ChainLink VRFConsumerBaseV2 fallback
    /// @dev only callable by the vrfCoordinator (cf.VRFConsumerBaseV2 and ChainLinkVRFv2 docs)
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address requestorAddress = _requestIdToCaller[requestId];
        IClooverRaffle(requestorAddress).draw(randomWords);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {IClooverRaffleFactorySetters} from "../interfaces/IClooverRaffleFactory.sol";

import {Errors} from "../libraries/Errors.sol";
import {ClooverRaffleFactoryEvents} from "../libraries/Events.sol";
import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {PercentageMath} from "../libraries/PercentageMath.sol";

import {ClooverRaffleFactoryStorage} from "./ClooverRaffleFactoryStorage.sol";

/// @title ClooverRaffleFactorySetters
/// @author Cloover
/// @notice Abstract contract exposing all setters and maintainer-related functions.
abstract contract ClooverRaffleFactorySetters is IClooverRaffleFactorySetters, ClooverRaffleFactoryStorage, Pausable {
    using PercentageMath for uint16;

    //----------------------------------------
    // Modifiers
    //----------------------------------------

    modifier onlyMaintainer() {
        IAccessController accessController = IAccessController(
            IImplementationManager(_implementationManager).getImplementationAddress(
                ImplementationInterfaceNames.AccessController
            )
        );
        if (!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    }

    //----------------------------------------
    // External function
    //----------------------------------------

    /// @inheritdoc IClooverRaffleFactorySetters
    function setProtocolFeeRate(uint16 newFeeRate) external onlyMaintainer {
        if (newFeeRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _config.protocolFeeRate = newFeeRate;
        emit ClooverRaffleFactoryEvents.ProtocolFeeRateUpdated(newFeeRate);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function setInsuranceRate(uint16 newinsuranceRate) external onlyMaintainer {
        if (newinsuranceRate > PercentageMath.PERCENTAGE_FACTOR) revert Errors.EXCEED_MAX_PERCENTAGE();
        _config.insuranceRate = newinsuranceRate;
        emit ClooverRaffleFactoryEvents.InsuranceRateUpdated(newinsuranceRate);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function setMinTicketSalesDuration(uint64 newMinTicketSalesDuration) external onlyMaintainer {
        if (newMinTicketSalesDuration >= _config.maxTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        _config.minTicketSalesDuration = newMinTicketSalesDuration;
        emit ClooverRaffleFactoryEvents.MinTicketSalesDurationUpdated(newMinTicketSalesDuration);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function setMaxTicketSalesDuration(uint64 newMaxTicketSalesDuration) external onlyMaintainer {
        if (newMaxTicketSalesDuration <= _config.minTicketSalesDuration) revert Errors.WRONG_DURATION_LIMITS();
        _config.maxTicketSalesDuration = newMaxTicketSalesDuration;
        emit ClooverRaffleFactoryEvents.MaxTicketSalesDurationUpdated(newMaxTicketSalesDuration);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function setMaxTicketSupplyAllowed(uint16 newMaxTotalSupplyAllowed) external onlyMaintainer {
        _config.maxTicketSupplyAllowed = newMaxTotalSupplyAllowed;
        emit ClooverRaffleFactoryEvents.MaxTotalSupplyAllowedUpdated(newMaxTotalSupplyAllowed);
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function pause() external onlyMaintainer {
        _pause();
    }

    /// @inheritdoc IClooverRaffleFactorySetters
    function unpause() external onlyMaintainer {
        _unpause();
    }
}

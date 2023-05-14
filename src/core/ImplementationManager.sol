// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title ImplementationManager
/// @author Cloover
/// @notice Contract that manages the list of contracts deployed for the protocol
contract ImplementationManager is IImplementationManager {
    //----------------------------------------
    // Storage
    //----------------------------------------

    mapping(bytes32 => address) public _interfacesImplemented;

    //----------------------------------------
    // Events
    //----------------------------------------

    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

    //----------------------------------------
    // Modifiers
    //----------------------------------------

    modifier onlyMaintainer() {
        IAccessController accessController =
            IAccessController(_interfacesImplemented[ImplementationInterfaceNames.AccessController]);
        if (!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    }

    //----------------------------------------
    // Initialization function
    //----------------------------------------
    constructor(address accessController) {
        _interfacesImplemented[ImplementationInterfaceNames.AccessController] = accessController;
    }

    //----------------------------------------
    // Externals functions
    //----------------------------------------

    /// @inheritdoc IImplementationManager
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress)
        external
        override
        onlyMaintainer
    {
        _interfacesImplemented[interfaceName] = implementationAddress;

        emit InterfaceImplementationChanged(interfaceName, implementationAddress);
    }

    /// @inheritdoc IImplementationManager
    function getImplementationAddress(bytes32 interfaceName)
        external
        view
        override
        returns (address implementationAddress)
    {
        implementationAddress = _interfacesImplemented[interfaceName];
        if (implementationAddress == address(0x0)) revert Errors.IMPLEMENTATION_NOT_FOUND();
    }
}

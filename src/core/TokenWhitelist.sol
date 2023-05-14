// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title TokenWhitelist
/// @author Cloover
/// @notice Contract managing the list of ERC20 that are allowed to be used in the protocol
contract TokenWhitelist is ITokenWhitelist {
    using EnumerableSet for EnumerableSet.AddressSet;

    //----------------------------------------
    // Storage
    //----------------------------------------

    EnumerableSet.AddressSet private _tokens;

    address private _implementationManager;

    //----------------------------------------
    // Events
    //----------------------------------------

    event AddedToWhitelist(address indexed addedToken);
    event RemovedFromWhitelist(address indexed removedToken);

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
    // Initialization function
    //----------------------------------------
    constructor(address implementationManager_) {
        _implementationManager = implementationManager_;
    }

    //----------------------------------------
    // External function
    //----------------------------------------

    /// @inheritdoc ITokenWhitelist
    function addToWhitelist(address newToken) external override onlyMaintainer {
        if (!_tokens.add(newToken)) revert Errors.ALREADY_WHITELISTED();
        emit AddedToWhitelist(newToken);
    }

    /// @inheritdoc ITokenWhitelist
    function removeFromWhitelist(address tokenToRemove) external override onlyMaintainer {
        if (!_tokens.remove(tokenToRemove)) revert Errors.NOT_WHITELISTED();
        emit RemovedFromWhitelist(tokenToRemove);
    }

    /// @inheritdoc ITokenWhitelist
    function isWhitelisted(address tokenToCheck) external view override returns (bool) {
        return _tokens.contains(tokenToCheck);
    }

    /// @inheritdoc ITokenWhitelist
    function getWhitelist() external view override returns (address[] memory) {
        uint256 numberOfElements = _tokens.length();
        address[] memory activeTokens = new address[](numberOfElements);
        for (uint256 i = 0; i < numberOfElements; ++i) {
            activeTokens[i] = _tokens.at(i);
        }
        return activeTokens;
    }

    /// @inheritdoc ITokenWhitelist
    function implementationManager() external view override returns (address) {
        return _implementationManager;
    }
}

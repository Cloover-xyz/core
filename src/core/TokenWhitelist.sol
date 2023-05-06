
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {ITokenWhitelist} from "../interfaces/ITokenWhitelist.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

contract TokenWhitelist is ITokenWhitelist{
    using EnumerableSet for EnumerableSet.AddressSet;

    //----------------------------------------
    // Storage
    //----------------------------------------

    EnumerableSet.AddressSet private tokens;
    
    IImplementationManager public implementationManager;

    //----------------------------------------
    // Events
    //----------------------------------------

    event AddedToWhitelist(address indexed addedToken);
    event RemovedFromWhitelist(address indexed removedToken);

    //----------------------------------------
    // Modifiers
    //----------------------------------------
    modifier onlyMaintainer() {
        IAccessController accessController = IAccessController(implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController));
        if(!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    }

    //----------------------------------------
    // Initialization function
    //----------------------------------------
    constructor(IImplementationManager _implementationManager){
        implementationManager = _implementationManager;
    }

    //----------------------------------------
    // External function
    //----------------------------------------
    
    /// @inheritdoc ITokenWhitelist
    function addToWhitelist(address newToken)
    external
    override
    onlyMaintainer
    {
        if(!tokens.add(newToken)) revert Errors.TOKEN_ALREADY_WHITELISTED();
        emit AddedToWhitelist(newToken);
    }

    /// @inheritdoc ITokenWhitelist
    function removeFromWhitelist(address tokenToRemove)
    external
    override
    onlyMaintainer
    {
        if(!tokens.remove(tokenToRemove)) revert Errors.TOKEN_NOT_WHITELISTED();
        emit RemovedFromWhitelist(tokenToRemove);
    }

    /// @inheritdoc ITokenWhitelist
    function isWhitelisted(address tokenToCheck)
    external
    view
    override
    returns (bool)
    {
        return tokens.contains(tokenToCheck);
    }

    /**
     * @notice Gets all addresses that are currently included in the whitelist.
     * @return The list of addresses on the whitelist.
     */
    function getWhitelist() external view returns (address[] memory) {
        uint256 numberOfElements = tokens.length();
        address[] memory activeTokens = new address[](numberOfElements);
        for (uint256 i = 0; i < numberOfElements; ++i) {
            activeTokens[i] = tokens.at(i);
        }
        return activeTokens;
    }
}
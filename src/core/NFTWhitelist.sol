// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {INFTWhitelist} from "../interfaces/INFTWhitelist.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title NFTWhitelist
/// @author Cloover
/// @notice Contract managing the list of NFT collections that are allowed to be used in the protocol
contract NFTWhitelist is INFTWhitelist {
    using EnumerableSet for EnumerableSet.AddressSet;

    //----------------------------------------
    // Storage
    //----------------------------------------

    EnumerableSet.AddressSet private _nftCollections;

    address private _implementationManager;

    mapping(address => address) private _royaltiesRecipent;

    //----------------------------------------
    // Events
    //----------------------------------------

    event AddedToWhitelist(address indexed addedNftCollection, address indexed royaltiesRecipent);
    event RemovedFromWhitelist(address indexed removedNftCollection);

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

    /// @inheritdoc INFTWhitelist
    function addToWhitelist(address newNftCollection, address royaltiesRecipent) external override onlyMaintainer {
        if (!_nftCollections.add(newNftCollection)) revert Errors.ALREADY_WHITELISTED();
        _royaltiesRecipent[newNftCollection] = royaltiesRecipent;
        emit AddedToWhitelist(newNftCollection, royaltiesRecipent);
    }

    /// @inheritdoc INFTWhitelist
    function removeFromWhitelist(address nftCollectionToRemove) external override onlyMaintainer {
        if (!_nftCollections.remove(nftCollectionToRemove)) revert Errors.NOT_WHITELISTED();
        delete _royaltiesRecipent[nftCollectionToRemove];
        emit RemovedFromWhitelist(nftCollectionToRemove);
    }

    /// @inheritdoc INFTWhitelist
    function isWhitelisted(address nftCollectionToCheck) external view override returns (bool) {
        return _nftCollections.contains(nftCollectionToCheck);
    }

    /// @inheritdoc INFTWhitelist
    function getWhitelist() external view override returns (address[] memory) {
        uint256 numberOfElements = _nftCollections.length();
        address[] memory activeNftCollections = new address[](numberOfElements);
        for (uint256 i = 0; i < numberOfElements; ++i) {
            activeNftCollections[i] = _nftCollections.at(i);
        }
        return activeNftCollections;
    }

    /// @inheritdoc INFTWhitelist
    function getCollectionRoyaltiesRecipient(address nftCollection) external view override returns (address creator) {
        return _royaltiesRecipent[nftCollection];
    }

    /// @inheritdoc INFTWhitelist
    function implementationManager() external view override returns (address) {
        return _implementationManager;
    }
}

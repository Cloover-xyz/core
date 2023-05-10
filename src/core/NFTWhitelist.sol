
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {INFTWhitelist} from "../interfaces/INFTWhitelist.sol";

import {ImplementationInterfaceNames} from "../libraries/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/Errors.sol";

/// @title NFTWhitelist
/// @author Cloover
/// @notice Contract managing the list of NFT collections that are allowed to be used in the protocol
contract NFTWhitelist is INFTWhitelist{
    using EnumerableSet for EnumerableSet.AddressSet;

    //----------------------------------------
    // Storage
    //----------------------------------------

    EnumerableSet.AddressSet private _nftCollections;
    
    IImplementationManager private _implementationManager;

    mapping(address => address) private _collectionToCreator;

    //----------------------------------------
    // Events
    //----------------------------------------

    event AddedToWhitelist(address indexed addedNftCollection, address indexed creator);
    event RemovedFromWhitelist(address indexed removedNftCollection);

    //----------------------------------------
    // Modifiers
    //----------------------------------------
    modifier onlyMaintainer() {
        IAccessController accessController = IAccessController(_implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController));
        if(!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
        _;
    }

    //----------------------------------------
    // Initialization function
    //----------------------------------------
    constructor(IImplementationManager implementationManager_){
        _implementationManager = implementationManager_;
    }

    //----------------------------------------
    // External function
    //----------------------------------------
    
    /// @inheritdoc INFTWhitelist
    function addToWhitelist(address newNftCollection, address creator)
    external
    override
    onlyMaintainer
    {
        if(!_nftCollections.add(newNftCollection)) revert Errors.ALREADY_WHITELISTED();
        _collectionToCreator[newNftCollection] = creator;
        emit AddedToWhitelist(newNftCollection, creator);
    }

    /// @inheritdoc INFTWhitelist
    function removeFromWhitelist(address nftCollectionToRemove)
    external
    override
    onlyMaintainer
    {
        if(!_nftCollections.remove(nftCollectionToRemove)) revert Errors.NOT_WHITELISTED();
        delete _collectionToCreator[nftCollectionToRemove];
        emit RemovedFromWhitelist(nftCollectionToRemove);
    }

    /// @inheritdoc INFTWhitelist
    function isWhitelisted(address nftCollectionToCheck)
    external
    view
    override
    returns (bool)
    {
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
    function getCollectionCreator(address nftCollection)
    external
    view
    override
    returns (address creator)
    {
        return _collectionToCreator[nftCollection];
    }

    /// @inheritdoc INFTWhitelist
    function implementationManager() external view override returns(IImplementationManager){
        return _implementationManager;
    }

}
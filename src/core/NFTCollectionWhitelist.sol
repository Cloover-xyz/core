
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from 'openzeppelin-contracts/contracts/utils/structs/EnumerableSet.sol';

import {IAccessController} from "../interfaces/IAccessController.sol";
import {IImplementationManager} from "../interfaces/IImplementationManager.sol";
import {INFTCollectionWhitelist} from "../interfaces/INFTCollectionWhitelist.sol";

import {ImplementationInterfaceNames} from "../libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "../libraries/helpers/Errors.sol";

contract NFTCollectionWhitelist is INFTCollectionWhitelist{
    using EnumerableSet for EnumerableSet.AddressSet;

    //----------------------------------------
    // Storage
    //----------------------------------------

    EnumerableSet.AddressSet private nftCollections;
    
    IImplementationManager public implementationManager;

    mapping(address => address) private collectionToCreator;

    //----------------------------------------
    // Events
    //----------------------------------------

    event AddedToWhitelist(address indexed addedNftCollection, address indexed creator);
    event RemovedFromWhitelist(address indexed removedNftCollection);

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
    
    /// @inheritdoc INFTCollectionWhitelist
    function addToWhitelist(address newNftCollection, address creator)
    external
    override
    onlyMaintainer
    {
        if(!nftCollections.add(newNftCollection)) revert Errors.COLLECTION_ALREADY_WHITELISTED();
        collectionToCreator[newNftCollection] = creator;
        emit AddedToWhitelist(newNftCollection, creator);
    }

    /// @inheritdoc INFTCollectionWhitelist
    function removeFromWhitelist(address nftCollectionToRemove)
    external
    override
    onlyMaintainer
    {
        if(!nftCollections.remove(nftCollectionToRemove)) revert Errors.COLLECTION_NOT_WHITELISTED();
        delete collectionToCreator[nftCollectionToRemove];
        emit RemovedFromWhitelist(nftCollectionToRemove);
    }

    /// @inheritdoc INFTCollectionWhitelist
    function isWhitelisted(address nftCollectionToCheck)
    external
    view
    override
    returns (bool)
    {
        return nftCollections.contains(nftCollectionToCheck);
    }

    /**
     * @notice Gets all addresses that are currently included in the whitelist.
     * @return The list of addresses on the whitelist.
     */
    function getWhitelist() external view returns (address[] memory) {
        uint256 numberOfElements = nftCollections.length();
        address[] memory activeNftCollections = new address[](numberOfElements);
        for (uint256 i = 0; i < numberOfElements; ++i) {
            activeNftCollections[i] = nftCollections.at(i);
        }
        return activeNftCollections;
    }

    /// @inheritdoc INFTCollectionWhitelist
    function getCollectionCreator(address nftCollection)
    external
    view
    override
    returns (address creator)
    {
        return collectionToCreator[nftCollection];
    }

}
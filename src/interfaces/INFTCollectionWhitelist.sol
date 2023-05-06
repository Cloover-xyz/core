// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface INFTCollectionWhitelist{

    /**
     * @notice Adds an address to the whitelist.
     * @param newNftCollection the new address to add.
     * @param creator the address of the collection creator.
     */
    function addToWhitelist(address newNftCollection, address creator) external;

    /**
     * @notice Removes an address from the whitelist.
     * @param nftCollectionToRemove The existing address to remove.
     */
    function removeFromWhitelist(address nftCollectionToRemove) external;

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param nftCollectionToCheck The address to check.
     * @return True if `collateralToCheck` is on the whitelist, or False.
     */
    function isWhitelisted(address nftCollectionToCheck) external view returns(bool);

    /**
     * @notice Return creator address for a specific nft collection.
     * @dev used to send royalties part of the raffle.
     * @param nftCollection The address to check.
     * @return creator address 
     */
    function getCollectionCreator(address nftCollection) external view returns(address creator);
}



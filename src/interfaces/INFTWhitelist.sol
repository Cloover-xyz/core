// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface INFTWhitelist {
    /// @notice Whitelist a nft collection with the creator address of it
    function addToWhitelist(address newNftCollection, address creator) external;

    /// @notice Removes a collection from the whitelist
    function removeFromWhitelist(address nftCollectionToRemove) external;

    /// @notice Return True if the address is whitelisted
    function isWhitelisted(address nftCollectionToCheck) external view returns (bool);

    /// @notice Return all addresses that are currently included in the whitelist.
    function getWhitelist() external view returns (address[] memory);

    /// @notice Return creator address for a specific nft collection
    function getCollectionCreator(address nftCollection) external view returns (address creator);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenWhitelist{

    /**
     * @notice Adds an address to the whitelist.
     * @param newToken the new address to add.
     */
    function addToWhitelist(address newToken) external;

    /**
     * @notice Removes an address from the whitelist.
     * @param tokenToRemove The existing address to remove.
     */
    function removeFromWhitelist(address tokenToRemove) external;

    /**
     * @notice Checks whether an address is on the whitelist.
     * @param tokenToCheck The address to check.
     * @return True if `tokenToCheck` is on the whitelist, or False.
     */
    function isWhitelisted(address tokenToCheck) external view returns(bool);
}



// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IImplementationManager} from "../interfaces/IImplementationManager.sol";

interface ITokenWhitelist{

    /// @notice Adds an address to the whitelist
    function addToWhitelist(address newToken) external;

    /// @notice Removes an address from the whitelist
    function removeFromWhitelist(address tokenToRemove) external;

    /// @notice Return True if the address is whitelisted
    function isWhitelisted(address tokenToCheck) external view returns(bool);

    /// @notice Return all addresses that are currently included in the whitelist.     
    function getWhitelist() external view returns (address[] memory);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns(IImplementationManager);
}



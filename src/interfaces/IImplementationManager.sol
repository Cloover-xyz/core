// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IImplementationManager {
    /// @notice Updates the address of the contract that implements `interfaceName`
    function changeImplementationAddress(bytes32 interfaceName, address implementationAddress) external;

    /// @notice Return the address of the contract that implements the given `interfaceName`
    function getImplementationAddress(bytes32 interfaceName) external view returns (address implementationAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {RandomProviderTypes} from "../libraries/Types.sol";

interface IRandomProvider {
    /// @notice Request a random numbers using ChainLinkVRFv2
    function requestRandomNumbers(uint32 numWords) external returns (uint256 requestId);

    /// @notice Return the raffle factory contract addres
    function clooverRaffleFactory() external view returns (address);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns (address);

    /// @notice Return the address of the contract that requested the random number from the requestId
    function requestorAddressFromRequestId(uint256 requestId) external view returns (address);

    /// @notice Return the ChainlinkVRFData struct
    function chainlinkVRFData() external view returns (RandomProviderTypes.ChainlinkVRFData memory);
}

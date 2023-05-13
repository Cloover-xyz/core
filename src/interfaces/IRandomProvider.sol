// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IRandomProvider {
    struct ChainlinkVRFData {
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        address vrfCoordinator;
        // The gas lane to use, which specifies the maximum gas price to bump to.
        // For a list of available gas lanes on each network,
        // see https://docs.chain.link/docs/vrf-contracts/#configurations
        bytes32 keyHash;
        // A reasonable default is 100000, but this value could be different
        // on other networks.
        uint32 callbackGasLimit;
        // The default is 3, but you can set this higher.
        uint16 requestConfirmations;
        uint64 subscriptionId;
    }

    /// @notice Request a random numbers using ChainLinkVRFv2
    function requestRandomNumbers(uint32 numWords) external returns (uint256 requestId);

    /// @notice Return the raffle factory contract addres
    function clooverRaffleFactory() external view returns (address);

    /// @notice Return the implementationManager contract address
    function implementationManager() external view returns (address);

    /// @notice Return the address of the contract that requested the random number from the requestId
    function requestorAddressFromRequestId(uint256 requestId) external view returns (address);

    /// @notice Return the ChainlinkVRFData struct
    function chainlinkVRFData() external view returns (ChainlinkVRFData memory);
}

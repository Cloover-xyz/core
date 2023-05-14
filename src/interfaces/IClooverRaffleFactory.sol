// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ClooverRaffleTypes} from "../libraries/Types.sol";

interface IClooverRaffleFactoryGetters {
    /// @notice Return the implementation manager contract
    function implementationManager() external view returns (address);

    /// @notice Return the fees rate to apply on ticket sales amount
    function protocolFeeRate() external view returns (uint256);

    /// @notice Return the rate that creator will have to pay as insurance on the min sales defined
    function insuranceRate() external view returns (uint256);

    /// @notice Return the max ticket supply allowed in a raffle
    function maxTotalSupplyAllowed() external view returns (uint256);

    /// @notice Return the min duration for the ticket sales
    function minTicketSalesDuration() external view returns (uint256);

    /// @notice Return the max duration for the ticket sales
    function maxTicketSalesDuration() external view returns (uint256);

    /// @notice Return the limit of duration for the ticket sales
    function ticketSalesDurationLimits() external view returns (uint256 minDuration, uint256 maxDuration);

    /// @notice Return Ture if raffle is registered
    function isRegistered(address raffle) external view returns (bool);

    /// @notice Return all raffle address that are currently included in the whitelist
    function getRegisteredRaffle() external view returns (address[] memory);

    /// @notice Return the version of the contract
    function version() external pure returns (string memory);
}

interface IClooverRaffleFactorySetters {
    /// @notice Set the protocol fees rate to apply on new raffle deployed
    function setProtocolFeeRate(uint16 newFeeRate) external;

    /// @notice Set the insurance rate to apply on new raffle deployed
    function setInsuranceRate(uint16 newinsuranceRate) external;

    /// @notice Set the min duration for the ticket sales
    function setMinTicketSalesDuration(uint64 newMinTicketSalesDuration) external;

    /// @notice Set the max duration for the ticket sales
    function setMaxTicketSalesDuration(uint64 newMaxTicketSalesDuration) external;

    /// @notice Set the max ticket supply allowed in a raffle
    function setMaxTotalSupplyAllowed(uint16 newMaxTotalSupplyAllowed) external;

    /// @notice Pause the contract preventing new raffle to be deployed
    /// @dev can only be called by the maintainer
    function pause() external;

    /// @notice Unpause the contract allowing new raffle to be deployed
    /// @dev can only be called by the maintainer
    function unpause() external;
}

interface IClooverRaffleFactory is IClooverRaffleFactoryGetters, IClooverRaffleFactorySetters {
    /// @notice Deploy a new raffle contract
    /// @dev must transfer the nft to the contract before initialize()
    function createNewRaffle(
        ClooverRaffleTypes.CreateRaffleParams memory params,
        ClooverRaffleTypes.PermitDataParams calldata permitData
    ) external payable returns (address newClooverRaffle);

    /// @notice remove msg.sender from the list of registered raffles
    function removeClooverRaffleFromRegister() external;
}

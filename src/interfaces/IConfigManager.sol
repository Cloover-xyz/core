// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IConfigManager{

    /// @notice Get the fees percentage to apply on ticket sales amount
    /// @return The fees percentage
    function procolFeesPercentage() external view returns(uint256);

    /// @notice Get the max ticket supply allowed for a raffle
    /// @return The max amount of ticket allowed
    function maxTicketSupplyAllowed() external view returns(uint256);

    /// @notice Get the min duration for the ticket sales
    /// @return Tthe min duration
    function minTicketSalesDuration() external view returns(uint256);

}
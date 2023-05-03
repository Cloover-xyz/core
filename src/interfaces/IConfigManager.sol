// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IConfigManager{

    /// @notice Get the fees rate to apply on ticket sales amount
    /// @return The fees rate
    function protocolFeeRate() external view returns(uint256);

    /// @notice Get the rate that creator will have to pay as insurance on the min sales defined
    /// @return The insurance rate
    function insuranceRate() external view returns(uint256);

    /// @notice Get the max ticket supply allowed in a raffle
    /// @return The max amount of max ticket supply 
    function maxTotalSupplyAllowed() external view returns(uint256);

    /// @notice Get the min duration for the ticket sales
    /// @return The min duration
    function minTicketSalesDuration() external view returns(uint256);
    
    /// @notice Get the max duration for the ticket sales
    /// @return Tthe max duration
    function maxTicketSalesDuration() external view returns(uint256);
    
    /// @notice Get the limit of duration for the ticket sales
    /// @return minDuration the minimum of time
    /// @return maxDuration the maximum of time
    function ticketSalesDurationLimits() external view returns(uint256 minDuration, uint256 maxDuration);

}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IConfigManager{

    /// @notice Set the new protocolFeesPercentage applied
    /// @dev Must be callable only by maintainer
    /// @param newFeePercentage the new value (100% = 1e4)
    function setProcolFeesPercentage(uint256 newFeePercentage) external;

    /// @notice Get the fees percentage to apply on ticket sales amount
    /// @return feesPercentage the return fees percentage
    function procolFeesPercentage() external view returns(uint256 feesPercentage);

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ConfiguratorInputTypes {
    
    struct InitConfigManagerInput{
        uint256 protocolFeesPercentage;
        uint256 maxTicketSupplyAllowed;
        uint256 minTicketSalesDuration;
        uint256 maxTicketSalesDuration;
        uint256 insuranceSalesPercentage;
    }
    
}
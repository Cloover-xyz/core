// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library ConfigManagerDataTypes {

    struct ProtocolConfigData{
        uint16 maxTotalSupplyAllowed;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint64 minTicketSalesDuration;
        uint64 maxTicketSalesDuration;
    }

    struct InitConfigManagerParams{
        uint16 maxTotalSupplyAllowed;
        uint16 protocolFeeRate;
        uint16 insuranceRate;
        uint64 minTicketSalesDuration;
        uint64 maxTicketSalesDuration;
    }
}
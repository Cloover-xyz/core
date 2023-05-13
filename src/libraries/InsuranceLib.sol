// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {PercentageMath} from "./PercentageMath.sol";

/// @title InsuranceLib
/// @author Cloover
/// @notice Library used to ease insurance maths
library InsuranceLib {
    using PercentageMath for uint256;

    /// @notice calculate the insurance cost
    function calculateInsuranceCost(uint16 minTicketSalesInsurance, uint16 insuranceRate, uint256 ticketPrice)
        internal
        pure
        returns (uint256 insuranceCost)
    {
        insuranceCost = (minTicketSalesInsurance * ticketPrice).percentMul(insuranceRate);
    }

    /// @notice calculate the part of insurance asign to each ticket and the protocol
    function splitInsuranceAmount(
        uint16 ticketSalesInsurance,
        uint16 insuranceRate,
        uint16 procolFeeRate,
        uint16 ticketSupply,
        uint256 ticketPrice
    ) internal pure returns (uint256 protocolFeeAmount, uint256 amountPerTicket) {
        uint256 insuranceAmount = calculateInsuranceCost(ticketSalesInsurance, insuranceRate, ticketPrice);
        amountPerTicket = (insuranceAmount - insuranceAmount.percentMul(procolFeeRate)) / ticketSupply;
        protocolFeeAmount = insuranceAmount - amountPerTicket * ticketSupply;
    }
}


// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {PercentageMath} from '../math/PercentageMath.sol';

/// @title InsuranceLib
/// @author Cloover
/// @notice Library used to calculate insurance data
library InsuranceLib {
    
    using PercentageMath for uint256;

    /**
     * @notice calculate the amount in insurance creator paid
     * @param minTicketSalesInsurance is the amount of ticket cover by the insurance
     * @param ticketPrice is the price of one ticket
     * @param insuranceRate is the percentage that the creator has to pay as insurance
     * @return insuranceCost the total cost
     */
    function calculateInsuranceCost(
        uint256 minTicketSalesInsurance,
        uint256 ticketPrice,
        uint256 insuranceRate
    ) internal pure returns(uint256 insuranceCost){
        insuranceCost = (minTicketSalesInsurance * ticketPrice).percentMul(
                insuranceRate
        );
    }

     function calculateInsuranceSplit(
        uint256 insuranceSalesPercentage,
        uint256 procolFeesPercentage,
        uint256 minTicketSalesInsurance,
        uint256 ticketPrice,
        uint256 ticketSupply
     )
        internal
        pure
        returns (uint256 treasuryAmount, uint256 insurancePartPerTicket)
    {
        uint256 insuranceCost = calculateInsuranceCost(
            minTicketSalesInsurance,
            ticketPrice,
            insuranceSalesPercentage
        );

        treasuryAmount = insuranceCost.percentMul(procolFeesPercentage);
        if(ticketSupply == 0) {
            return(treasuryAmount, 0);
        }

        insurancePartPerTicket = (insuranceCost - treasuryAmount) / ticketSupply;
        //Avoid dust
        treasuryAmount =
            insuranceCost -
            insurancePartPerTicket *
            ticketSupply;
    }
}
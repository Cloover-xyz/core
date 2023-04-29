
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PercentageMath} from '../math/PercentageMath.sol';

library InsuranceLogic{
    
    using PercentageMath for uint256;

    function calculateInsuranceCost(
        uint256 minTicketSalesInsurance,
        uint256 ticketPrice,
        uint256 insurancePercentage
    ) internal pure returns(uint256 insuranceAmount){
        insuranceAmount = (minTicketSalesInsurance * ticketPrice).percentMul(
                insurancePercentage
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
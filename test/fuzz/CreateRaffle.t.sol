// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/FuzzTest.sol";

contract CreateRaffleFuzzTest is FuzzTest {
    function testFuzz_CreateTokenRaffle(
        bool hasInsurance,
        bool hasRoyalties,
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) external {
        raffle = _createFuzzRaffle(
            false,
            hasInsurance,
            hasRoyalties,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );
        assertFalse(raffle.isEthRaffle());
    }

    function testFuzz_CreateEthRaffle(
        bool hasInsurance,
        bool hasRoyalties,
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) external {
        raffle = _createFuzzRaffle(
            true,
            hasInsurance,
            hasRoyalties,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );
        assertTrue(raffle.isEthRaffle());
    }
}

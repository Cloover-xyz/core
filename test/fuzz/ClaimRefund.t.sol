// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/FuzzTest.sol";

contract ClaimRefundFuzzTest is FuzzTest {
    using PercentageMath for uint256;
    using InsuranceLib for uint16;

    function testFuzz_UserClaimRefundSplitCorrectly(
        uint16 ticketSupply,
        uint16 ticketSaleInsurance,
        address participant1,
        uint16 nbOfTicketPurchasedByParticipant1,
        address participant2,
        uint16 nbOfTicketPurchasedByParticipant2
    ) external {
        vm.assume(
            participant1 != participant2 && nbOfTicketPurchasedByParticipant1 > 0
                && nbOfTicketPurchasedByParticipant2 > 0
        );
        ticketSupply = _boundMaxTotalSupply(ticketSupply);
        ticketSaleInsurance = uint16(_boundAmountNotZeroUnderOf(ticketSupply / 2, ticketSupply));
        raffle = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            ticketSupply,
            0,
            ticketSaleInsurance,
            0
        );
        vm.assume(address(raffle) != participant1 && address(raffle) != participant2);
        assertEq(erc20Mock.balanceOf(address(raffle)), raffle.insurancePaid());
        nbOfTicketPurchasedByParticipant1 =
            uint16(_boundAmountNotZeroUnderOf(nbOfTicketPurchasedByParticipant1, (ticketSaleInsurance / 2) - 1));
        _purchaseExactAmountOfTickets(raffle, participant1, nbOfTicketPurchasedByParticipant1);

        assertEq(
            erc20Mock.balanceOf(address(raffle)),
            raffle.insurancePaid() + (nbOfTicketPurchasedByParticipant1 * initialTicketPrice)
        );

        nbOfTicketPurchasedByParticipant2 =
            uint16(_boundAmountNotZeroUnderOf(nbOfTicketPurchasedByParticipant2, (ticketSaleInsurance / 2) - 1));
        _purchaseExactAmountOfTickets(raffle, participant2, nbOfTicketPurchasedByParticipant2);

        assertEq(
            erc20Mock.balanceOf(address(raffle)),
            raffle.insurancePaid() + (nbOfTicketPurchasedByParticipant1 * initialTicketPrice)
                + (nbOfTicketPurchasedByParticipant2 * initialTicketPrice)
        );

        _forwardByTimestamp(initialTicketSalesDuration + 1);

        uint256 insuranceCost = raffle.insurancePaid();
        (uint256 treasuryAmount, uint256 amountPerTicket) = ticketSaleInsurance.splitInsuranceAmount(
            INSURANCE_RATE,
            PROTOCOL_FEE_RATE,
            (nbOfTicketPurchasedByParticipant1 + nbOfTicketPurchasedByParticipant2),
            initialTicketPrice
        );
        uint256 participant1TicketCost = nbOfTicketPurchasedByParticipant1 * initialTicketPrice;
        uint256 expectedParticipant1Refund = nbOfTicketPurchasedByParticipant1 * (amountPerTicket + initialTicketPrice);
        uint256 participant2TicketCost = nbOfTicketPurchasedByParticipant2 * initialTicketPrice;
        uint256 expectedParticipant2Refund = nbOfTicketPurchasedByParticipant2 * (amountPerTicket + initialTicketPrice);

        assertEq(erc20Mock.balanceOf(address(raffle)), insuranceCost + participant1TicketCost + participant2TicketCost);
        assertEq(
            erc20Mock.balanceOf(address(raffle)),
            treasuryAmount + expectedParticipant1Refund + expectedParticipant2Refund
        );

        uint256 balanceParticipant1Before = erc20Mock.balanceOf(participant1);
        changePrank(participant1);
        raffle.claimParticipantRefund();
        assertEq(erc20Mock.balanceOf(participant1), balanceParticipant1Before + expectedParticipant1Refund);

        uint256 balanceParticipant2Before = erc20Mock.balanceOf(participant2);
        changePrank(participant2);
        raffle.claimParticipantRefund();
        assertEq(erc20Mock.balanceOf(participant2), balanceParticipant2Before + expectedParticipant2Refund);

        assertEq(erc20Mock.balanceOf(address(raffle)), treasuryAmount);
    }
}

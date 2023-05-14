// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleWinnerClaimTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_WinnerClaim(bool isEthRaffle, bool hasInsurance) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, false);

        changePrank(participant);
        uint16 min = raffle.ticketSalesInsurance();
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTicketsBetween(raffle, participant, min, max);

        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.draw();
        _generateRandomNumbersFromRandomProvider(address(raffle), false);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.WinnerClaimed(participant);
        raffle.winnerClaim();

        assertEq(erc721Mock.ownerOf(nftId), participant);
    }

    function test_WinnerClaim_RevertWhen_NotWinnerCalling(bool isEthRaffle, bool hasInsurance, address caller)
        external
    {
        vm.assume(participant != caller);
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, false);

        changePrank(participant);
        uint16 min = raffle.ticketSalesInsurance();
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTicketsBetween(raffle, participant, min, max);

        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.draw();
        _generateRandomNumbersFromRandomProvider(address(raffle), false);

        changePrank(caller);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        raffle.winnerClaim();
    }

    function test_WinnerClaim_RevertWhen_DrawnHasNotBeDone(bool isEthRaffle, bool hasInsurance) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, false);

        changePrank(participant);
        uint16 min = raffle.ticketSalesInsurance();
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTicketsBetween(raffle, participant, min, max);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        raffle.winnerClaim();
    }
}
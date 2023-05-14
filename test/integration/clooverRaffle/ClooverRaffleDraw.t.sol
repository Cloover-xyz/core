// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleDrawTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_Draw(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, false, false);

        changePrank(participant);
        uint16 maxTotalSupply = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant, maxTotalSupply);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.DRAWNING);
        raffle.draw();

        vm.expectEmit(true, true, true, false);
        emit ClooverRaffleEvents.WinningTicketDrawn(1);
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.DRAWN);
        _generateRandomNumbersFromRandomProvider(address(raffle), false);

        assertFalse(raffle.winnerAddress() == address(0));
        assertTrue(raffle.winnerAddress() == participant);
        assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.Status.DRAWN);
    }

    function test_Draw_RevertWhen_TicketSalesStillOpen(bool isEthRaffle, bool hasInsurance) external {
        (raffle,) = _createRandomRaffle(isEthRaffle, hasInsurance, false);

        changePrank(participant);
        uint16 maxTotalSupply = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant, maxTotalSupply);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        raffle.draw();
    }

    function test_Draw_StatusBackToInitWhenRandomNumberTicketDrawnedIsZero(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, false, false);

        changePrank(participant);
        uint16 maxTotalSupply = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant, maxTotalSupply);

        _forwardByTimestamp(ticketSalesDuration + 1);
        raffle.draw();

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.DEFAULT);
        _generateRandomNumbersFromRandomProvider(address(raffle), true);
        assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.Status.DEFAULT);
    }

    function test_Draw_StatusSetToRefundWhenTicketSoldAmountUnderInsuranceAmount(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);
        uint16 insuranceAmount = raffle.ticketSalesInsurance();
        changePrank(participant);
        _purchaseRandomAmountOfTickets(raffle, participant, insuranceAmount - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.INSURANCE);
        raffle.draw();
        assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.Status.INSURANCE);
    }

    function test_Draw_RevertWhen_TicketAlreadyDrawn(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, false, false);

        changePrank(participant);
        uint16 maxTotalSupply = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant, maxTotalSupply);

        _forwardByTimestamp(ticketSalesDuration + 1);
        raffle.draw();

        _generateRandomNumbersFromRandomProvider(address(raffle), false);

        vm.expectRevert(Errors.DRAW_NOT_POSSIBLE.selector);
        raffle.draw();
    }

    function test_Draw_StatusSetToCancelWhenNoTicketSoldAfterOpenWindows(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, false, false);
        _forwardByTimestamp(ticketSalesDuration + 1);
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.CANCELLED);
        raffle.draw();
        assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.Status.CANCELLED);
    }

    function test_Draw_RevertWhen_RaffleStatusIsCancel(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, false, false);
        _forwardByTimestamp(ticketSalesDuration + 1);
        raffle.draw();

        vm.expectRevert(Errors.DRAW_NOT_POSSIBLE.selector);
        raffle.draw();
    }

    function test_Draw_RevertWhen_NotRamdonProviderContractCalling(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, false, false);

        changePrank(participant);
        uint16 maxTotalSupply = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant, maxTotalSupply);

        _forwardByTimestamp(ticketSalesDuration + 1);
        uint256[] memory randomNumbers = new uint256[](1);
        randomNumbers[0] = 1;
        vm.expectRevert(Errors.NOT_RANDOM_PROVIDER_CONTRACT.selector);
        raffle.draw(randomNumbers);
    }
}

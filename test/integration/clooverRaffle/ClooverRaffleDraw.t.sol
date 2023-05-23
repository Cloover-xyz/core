// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleDrawTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_Draw() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);
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
    }

    function test_Draw_RevertWhen_TicketSalesStillOpen() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
            raffle.draw();
        }
    }

    function test_Draw_StatusBackToDefaultWhenRandomNumberTicketDrawnedIsZero() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);
            raffle.draw();

            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.DEFAULT);
            _generateRandomNumbersFromRandomProvider(address(raffle), true);
            assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.Status.DEFAULT);
        }
    }

    function test_Draw_StatusSetToRefundWhenTicketSoldAmountUnderInsuranceAmount() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.ticketSalesInsurance() == 0) continue;

            changePrank(participant);

            _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance() - 1);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.INSURANCE);
            raffle.draw();
            assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.Status.INSURANCE);
        }
    }

    function test_Draw_PossibleWhenTicketSoldIsEqualToSalesInsurance() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.ticketSalesInsurance() == 0) continue;

            changePrank(participant);

            _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance());

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.DRAWNING);
            raffle.draw();
            assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.Status.DRAWNING);
        }
    }

    function test_Draw_RevertWhen_TicketAlreadyDrawn() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance() + 1);

            _forwardByTimestamp(initialTicketSalesDuration + 1);
            raffle.draw();

            vm.expectRevert(Errors.DRAW_NOT_POSSIBLE.selector);
            raffle.draw();
        }
    }

    function test_Draw_StatusSetToCancelWhenNoTicketSoldAfterOpenWindows() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.CANCELLED);
            raffle.draw();
            assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.Status.CANCELLED);
        }
    }

    function test_Draw_RevertWhen_RaffleStatusIsCancel() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            raffle.draw();

            vm.expectRevert(Errors.DRAW_NOT_POSSIBLE.selector);
            raffle.draw();
        }
    }

    function test_Draw_RevertWhen_NotRamdonProviderContractCalling() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance() + 1);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            changePrank(hacker);
            raffle.draw();

            uint256[] memory randomNumbers = new uint256[](1);
            randomNumbers[0] = 1;
            vm.expectRevert(Errors.NOT_RANDOM_PROVIDER_CONTRACT.selector);
            raffle.draw(randomNumbers);
        }
    }
}

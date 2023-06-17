// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleWinnerClaimTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_WinnerClaim() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            raffle.draw();
            _generateRandomNumbersFromRandomProvider(address(raffle), false);

            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.WinnerClaimed(participant);
            raffle.claimPrize();
            assertEq(erc721Mock.ownerOf(nftId), participant);
        }
    }

    function test_WinnerClaim_RevertWhen_NotWinnerCalling() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            raffle.draw();
            _generateRandomNumbersFromRandomProvider(address(raffle), false);

            changePrank(hacker);
            vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
            raffle.claimPrize();
        }
    }

    function test_WinnerClaim_RevertWhen_DrawnHasNotBeDone() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);
            vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
            raffle.claimPrize();
        }
    }
}

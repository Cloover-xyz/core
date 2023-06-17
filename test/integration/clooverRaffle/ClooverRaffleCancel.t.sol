// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleCancelTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();

        changePrank(creator);
    }

    function test_CancelRaffle() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.CANCELLED);
            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.RaffleCancelled();
            raffle.cancel();

            assertEq(erc20Mock.balanceOf(address(raffle)), 0);
            assertEq(address(raffle).balance, 0);
            assertEq(erc721Mock.ownerOf(nftId), creator);
        }
    }

    function test_CancelRaffle_WhenStatusIsAlreadyCancelled() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            _forwardByTimestamp(initialTicketSalesDuration + 1);
            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.RaffleStatus(ClooverRaffleTypes.Status.CANCELLED);
            raffle.draw();

            raffle.cancel();
            assertEq(erc20Mock.balanceOf(address(raffle)), 0);
            assertEq(address(raffle).balance, 0);
            assertEq(erc721Mock.ownerOf(nftId), creator);
        }
    }

    function test_CancelRaffle_RevertWhen_NotCreatorCalling() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(hacker);
            vm.expectRevert(Errors.NOT_CREATOR.selector);
            raffle.cancel();
        }
    }

    function test_CancelRaffle_RevertWhen_AtLeastOneTicketHasBeenSold() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            _purchaseExactAmountOfTickets(raffle, participant, 1);

            changePrank(creator);
            vm.expectRevert(Errors.SALES_ALREADY_STARTED.selector);
            raffle.cancel();
        }
    }

    function test_CancelRaffle_RefundInsurancePaid() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            uint256 insurancePaid = raffle.insurancePaid();
            if (insurancePaid == 0) continue;

            uint256 balanceBefore = address(creator).balance;
            if (isEthRaffle) {
                raffle.cancel();
                assertEq(address(creator).balance, balanceBefore + insurancePaid);
            } else {
                balanceBefore = erc20Mock.balanceOf(address(creator));
                raffle.cancel();
                assertEq(erc20Mock.balanceOf(address(creator)), balanceBefore + insurancePaid);
            }
        }
    }
}

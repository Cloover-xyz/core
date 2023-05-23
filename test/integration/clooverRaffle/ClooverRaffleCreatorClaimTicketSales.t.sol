// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleCreatorClaimTicketSalesTest is IntegrationTest {
    using PercentageMath for uint256;

    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_CreatorClaimTicketSales() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);
            uint256 totalSalesAmount = raffle.ticketPrice() * nbOfTicketsPurchased;

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            raffle.draw();
            _generateRandomNumbersFromRandomProvider(address(raffle), false);

            uint256 creatorBalanceBefore = address(creator).balance;
            uint256 collectionCreatorBalanceBefore = address(collectionCreator).balance;
            uint256 treasuryBalanceBefore = address(treasury).balance;

            uint16 royaltiesRate = raffle.royaltiesRate();
            uint256 insurancePaid = raffle.insurancePaid();
            uint256 expectedTreasuryAmountReceived = totalSalesAmount.percentMul(PROTOCOL_FEE_RATE);
            uint256 expectedRoyaltiesAmountReceived = totalSalesAmount.percentMul(royaltiesRate);
            uint256 expectedCreatorAmountReceived =
                totalSalesAmount - expectedTreasuryAmountReceived - expectedRoyaltiesAmountReceived;

            changePrank(creator);
            if (isEthRaffle) {
                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.CreatorClaimed(
                    expectedCreatorAmountReceived + insurancePaid,
                    expectedTreasuryAmountReceived,
                    expectedRoyaltiesAmountReceived
                );
                raffle.creatorClaimTicketSalesInEth();
                assertEq(address(creator).balance, insurancePaid + creatorBalanceBefore + expectedCreatorAmountReceived);
                assertEq(address(treasury).balance, expectedTreasuryAmountReceived + treasuryBalanceBefore);
                assertEq(
                    address(collectionCreator).balance, expectedRoyaltiesAmountReceived + collectionCreatorBalanceBefore
                );
                assertEq(address(raffle).balance, 0);
            } else {
                creatorBalanceBefore = erc20Mock.balanceOf(creator);
                collectionCreatorBalanceBefore = erc20Mock.balanceOf(collectionCreator);
                treasuryBalanceBefore = erc20Mock.balanceOf(treasury);
                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.CreatorClaimed(
                    expectedCreatorAmountReceived + insurancePaid,
                    expectedTreasuryAmountReceived,
                    expectedRoyaltiesAmountReceived
                );
                raffle.creatorClaimTicketSales();
                assertEq(
                    erc20Mock.balanceOf(address(creator)),
                    insurancePaid + creatorBalanceBefore + expectedCreatorAmountReceived
                );
                assertEq(erc20Mock.balanceOf(treasury), expectedTreasuryAmountReceived + treasuryBalanceBefore);
                assertEq(
                    erc20Mock.balanceOf(collectionCreator),
                    expectedRoyaltiesAmountReceived + collectionCreatorBalanceBefore
                );
                assertEq(erc20Mock.balanceOf(address(raffle)), 0);
            }
        }
    }

    function test_CreatorClaimTicketSales_RevertWhen_NotCreatorCalling() external {
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

            changePrank(participant);
            vm.expectRevert(Errors.NOT_CREATOR.selector);
            if (isEthRaffle) {
                raffle.creatorClaimTicketSalesInEth();
            } else {
                raffle.creatorClaimTicketSales();
            }
        }
    }

    function test_CreatorClaimTicketSales_RevertWhen_NotCorrectTypeOfRaffle() external {
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

            changePrank(creator);
            if (isEthRaffle) {
                vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
                raffle.creatorClaimTicketSales();
            } else {
                vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
                raffle.creatorClaimTicketSalesInEth();
            }
        }
    }

    function test_CreatorClaimTicketSales_RevertWhen_WinningTicketNotDrawn() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            changePrank(creator);
            vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
            if (isEthRaffle) {
                raffle.creatorClaimTicketSalesInEth();
            } else {
                raffle.creatorClaimTicketSales();
            }
        }
    }
}

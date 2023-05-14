// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleCreatorClaimTicketSalesTest is IntegrationTest {
    using PercentageMath for uint256;

    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_CreatorClaimTicketSales(bool isEthRaffle, bool hasInsurance, bool hasRoyalties) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, hasRoyalties);

        changePrank(participant);
        uint16 min = raffle.ticketSalesInsurance();
        uint16 max = raffle.maxTotalSupply();
        (uint256 ticketPurchased) = _purchaseRandomAmountOfTicketsBetween(raffle, participant, min, max);

        uint256 totalSalesAmount = raffle.ticketPrice() * ticketPurchased;

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.draw();
        _generateRandomNumbersFromRandomProvider(address(raffle), false);

        uint16 royaltiesRate = raffle.royaltiesRate();
        uint256 creatorBalanceBefore = address(creator).balance;
        uint256 insurancePaid = raffle.insurancePaid();
        uint256 expectedTreasuryAmountReceived = totalSalesAmount.percentMul(PROTOCOL_FEE_RATE);
        uint256 expectedRoyaltiesAmountReceived = totalSalesAmount.percentMul(royaltiesRate);
        uint256 expectedCreatorAmountReceived =
            totalSalesAmount - expectedTreasuryAmountReceived - expectedRoyaltiesAmountReceived;

        if (isEthRaffle) {
            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.CreatorClaimed(
                expectedCreatorAmountReceived + insurancePaid,
                expectedTreasuryAmountReceived,
                expectedRoyaltiesAmountReceived
            );
            raffle.creatorClaimTicketSalesInEth();
            assertEq(address(creator).balance, insurancePaid + creatorBalanceBefore + expectedCreatorAmountReceived);
            assertEq(address(treasury).balance, expectedTreasuryAmountReceived);
            assertEq(address(collectionCreator).balance, expectedRoyaltiesAmountReceived);
            assertEq(address(raffle).balance, 0);
        } else {
            creatorBalanceBefore = erc20Mock.balanceOf(creator);
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
            assertEq(erc20Mock.balanceOf(treasury), expectedTreasuryAmountReceived);
            assertEq(erc20Mock.balanceOf(collectionCreator), expectedRoyaltiesAmountReceived);
            assertEq(erc20Mock.balanceOf(address(raffle)), 0);
        }
    }

    function test_CreatorClaimTicketSales_RevertWhen_NotCreatorCalling(
        bool isEthRaffle,
        bool hasInsurance,
        bool hasRoyalties,
        address caller
    ) external {
        vm.assume(creator != caller);
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, hasRoyalties);

        changePrank(participant);
        uint16 min = raffle.ticketSalesInsurance();
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTicketsBetween(raffle, participant, min, max);

        changePrank(caller);
        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.draw();
        _generateRandomNumbersFromRandomProvider(address(raffle), false);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        if (isEthRaffle) {
            raffle.creatorClaimTicketSalesInEth();
        } else {
            raffle.creatorClaimTicketSales();
        }
    }

    function test_CreatorClaimTicketSales_RevertWhen_NotCorrectTypeOfRaffle(
        bool isEthRaffle,
        bool hasInsurance,
        bool hasRoyalties
    ) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, hasRoyalties);

        changePrank(participant);
        uint16 min = raffle.ticketSalesInsurance();
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTicketsBetween(raffle, participant, min, max);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.draw();
        _generateRandomNumbersFromRandomProvider(address(raffle), false);

        if (isEthRaffle) {
            vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
            raffle.creatorClaimTicketSales();
        } else {
            vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
            raffle.creatorClaimTicketSalesInEth();
        }
    }

    function test_CreatorClaimTicketSales_RevertWhen_WinningTicketNotDrawn(
        bool isEthRaffle,
        bool hasInsurance,
        bool hasRoyalties
    ) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, hasInsurance, hasRoyalties);

        changePrank(participant);
        uint16 min = raffle.ticketSalesInsurance();
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTicketsBetween(raffle, participant, min, max);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        if (isEthRaffle) {
            raffle.creatorClaimTicketSalesInEth();
        } else {
            raffle.creatorClaimTicketSales();
        }
    }
}

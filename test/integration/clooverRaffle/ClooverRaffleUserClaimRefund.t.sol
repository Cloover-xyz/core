// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleUserClaimRefundTest is IntegrationTest {
    using PercentageMath for uint256;
    using InsuranceLib for uint16;

    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_UserClaimRefund(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        (uint256 ticketPurchased) = _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        uint256 totalSalesAmount = raffle.ticketPrice() * ticketPurchased;

        (uint256 treasuryAmount, uint256 amountPerTicket) =
            max.splitInsuranceAmount(INSURANCE_RATE, PROTOCOL_FEE_RATE, raffle.currentSupply(), raffle.ticketPrice());
        uint256 expectParticipant1Refund = amountPerTicket * ticketPurchased + totalSalesAmount;
        uint256 expectedBalanceLeftOnContract = treasuryAmount;
        uint256 parcipant1BalanceBefore = address(participant).balance;

        if (isEthRaffle) {
            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.UserClaimedRefund(participant, expectParticipant1Refund);
            raffle.userClaimRefundInEth();
            assertEq(address(raffle).balance, expectedBalanceLeftOnContract);
            assertEq(address(participant).balance, parcipant1BalanceBefore + expectParticipant1Refund);
        } else {
            parcipant1BalanceBefore = erc20Mock.balanceOf(participant);
            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.UserClaimedRefund(participant, expectParticipant1Refund);
            raffle.userClaimRefund();
            assertEq(erc20Mock.balanceOf(address(raffle)), expectedBalanceLeftOnContract);
            assertEq(erc20Mock.balanceOf(address(participant)), parcipant1BalanceBefore + expectParticipant1Refund);
        }
    }

    function test_UserClaimRefund_RevertWhen_NotCorrectTypeOfRaffle(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        if (isEthRaffle) {
            vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
            raffle.userClaimRefund();
        } else {
            vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
            raffle.userClaimRefundInEth();
        }
    }

    function test_UserClaimRefund_RevertWhen_TicketSupplyGreaterThanMinInsuranceSales(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant);

        _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance());

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        if (isEthRaffle) {
            raffle.userClaimRefundInEth();
        } else {
            raffle.userClaimRefund();
        }
    }

    function test_UserClaimRefund_RevertWhen_UserAlreadyClaimedRefund(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        if (isEthRaffle) {
            raffle.userClaimRefundInEth();
            vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
            raffle.userClaimRefundInEth();
        } else {
            raffle.userClaimRefund();
            vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
            raffle.userClaimRefund();
        }
    }

    function test_UserClaimRefund_RevertWhen_UserAlreadyClaimedRefund(bool isEthRaffle, address caller) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        changePrank(caller);

        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        if (isEthRaffle) {
            raffle.userClaimRefundInEth();
        } else {
            raffle.userClaimRefund();
        }
    }
}

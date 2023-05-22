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

    function test_UserClaimRefund_TokenRaffle(uint256 randomValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

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
        parcipant1BalanceBefore = erc20Mock.balanceOf(participant);
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.UserClaimedRefund(participant, expectParticipant1Refund);
        raffle.userClaimRefund();
        assertEq(erc20Mock.balanceOf(address(raffle)), expectedBalanceLeftOnContract);
        assertEq(erc20Mock.balanceOf(address(participant)), parcipant1BalanceBefore + expectParticipant1Refund);
    }

    function test_UserClaimRefund_EthRaffle(uint256 randomValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

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

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.UserClaimedRefund(participant, expectParticipant1Refund);
        raffle.userClaimRefundInEth();
        assertEq(address(raffle).balance, expectedBalanceLeftOnContract);
        assertEq(address(participant).balance, parcipant1BalanceBefore + expectParticipant1Refund);
    }

    function test_UserClaimRefund_TokenRaffle_RevertWhen_NotCorrectTypeOfRaffle(uint256 randomValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        raffle.userClaimRefundInEth();
    }

    function test_UserClaimRefund_EthRaffle_RevertWhen_NotCorrectTypeOfRaffle(uint256 randomValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        raffle.userClaimRefund();
    }

    function test_UserClaimRefund_TokenRaffle_RevertWhen_TicketSupplyGreaterThanMinInsuranceSales(uint256 randomValue)
        external
    {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);

        _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance());

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);

        raffle.userClaimRefund();
    }

    function test_UserClaimRefund_EthRaffle_RevertWhen_TicketSupplyGreaterThanMinInsuranceSales(uint256 randomValue)
        external
    {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);

        _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance());

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);

        raffle.userClaimRefundInEth();
    }

    function test_UserClaimRefund_TokenRaffle_RevertWhen_UserAlreadyClaimedRefund(uint256 randomValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.userClaimRefund();
        vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
        raffle.userClaimRefund();
    }

    function test_UserClaimRefund_EthRaffle_RevertWhen_UserAlreadyClaimedRefund(uint256 randomValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.userClaimRefundInEth();
        vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
        raffle.userClaimRefundInEth();
    }

    function test_UserClaimRefund_TokenRaffle_RevertWhen_NothingToClaim(address caller) external {
        vm.assume(caller != participant);
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        changePrank(caller);

        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);

        raffle.userClaimRefund();
    }

    function test_UserClaimRefund_EthRaffle_RevertWhen_NothingToClaim(address caller) external {
        vm.assume(caller != participant);
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        changePrank(caller);

        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);

        raffle.userClaimRefundInEth();
    }
}

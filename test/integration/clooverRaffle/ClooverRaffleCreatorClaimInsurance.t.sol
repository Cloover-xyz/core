// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleCreatorClaimInsuranceTest is IntegrationTest {
    using PercentageMath for uint256;

    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_CreatorClaimInsurance_TokenRaffle(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        (uint256 ticketPurchased) = _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        uint256 totalSalesAmount = raffle.ticketPrice() * ticketPurchased;
        uint256 insurancePaid = raffle.insurancePaid();

        uint256 treasuryAmount = insurancePaid.percentMul(PROTOCOL_FEE_RATE);

        uint256 creatorBalanceBefore = address(creator).balance;
        uint256 expectedBalanceLeftOnContract = insurancePaid - treasuryAmount + totalSalesAmount;

        creatorBalanceBefore = erc20Mock.balanceOf(creator);
        uint256 treasuryBalanceBefore = erc20Mock.balanceOf(treasury);
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.CreatorClaimedInsurance();
        raffle.creatorClaimInsurance();
        assertEq(erc20Mock.balanceOf(address(raffle)), expectedBalanceLeftOnContract);
        assertEq(erc20Mock.balanceOf(treasury), treasuryBalanceBefore + treasuryAmount);
        assertEq(erc20Mock.balanceOf(address(creator)), creatorBalanceBefore);

        assertEq(erc721Mock.ownerOf(nftId), creator);
    }

    function test_CreatorClaimInsurance_EthRaffle(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        (uint256 ticketPurchased) = _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        uint256 totalSalesAmount = raffle.ticketPrice() * ticketPurchased;
        uint256 insurancePaid = raffle.insurancePaid();

        uint256 treasuryAmount = insurancePaid.percentMul(PROTOCOL_FEE_RATE);

        uint256 creatorBalanceBefore = address(creator).balance;
        uint256 expectedBalanceLeftOnContract = insurancePaid - treasuryAmount + totalSalesAmount;

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleEvents.CreatorClaimedInsurance();
        raffle.creatorClaimInsuranceInEth();
        assertEq(address(raffle).balance, expectedBalanceLeftOnContract);
        assertEq(address(treasury).balance, treasuryAmount);
        assertEq(address(creator).balance, creatorBalanceBefore);

        assertEq(erc721Mock.ownerOf(nftId), creator);
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_AlreadyClaimed(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.creatorClaimInsurance();
        vm.expectRevert();
        raffle.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_EthRaffle_RevertWhen_AlreadyClaimed(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        raffle.creatorClaimInsuranceInEth();
        vm.expectRevert();
        raffle.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_NotCorrectTypeOfRaffle(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        raffle.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsurance_EthRaffle_RevertWhen_NotCorrectTypeOfRaffle(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        raffle.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_CreatorDidNotTookInsurance(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, false, false);

        changePrank(participant);
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant, max);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);
        vm.expectRevert(Errors.NO_INSURANCE_TAKEN.selector);

        raffle.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_EthRaffle_RevertWhen_CreatorDidNotTookInsurance(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, false, false);

        changePrank(participant);
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant, max);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);
        vm.expectRevert(Errors.NO_INSURANCE_TAKEN.selector);

        raffle.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_NotCreatorCalling(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.NOT_CREATOR.selector);

        raffle.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_EthRaffle_RevertWhen_NotCreatorCalling(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.NOT_CREATOR.selector);

        raffle.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_NoTicketHaveBeenSold(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);

        raffle.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_EthRaffle_RevertWhen_NoTicketHaveBeenSold(uint256 fuzzValue) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);

        raffle.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_TicketSalesAreEqualOrHigherThanInsurance(
        uint256 fuzzValue
    ) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(false, true, false);

        changePrank(participant);

        _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance());

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);

        raffle.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_EthRaffle_RevertWhen_TicketSalesAreEqualOrHigherThanInsurance(uint256 fuzzValue)
        external
    {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(true, true, false);

        changePrank(participant);

        _purchaseExactAmountOfTickets(raffle, participant, raffle.ticketSalesInsurance());

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);

        raffle.creatorClaimInsuranceInEth();
    }
}

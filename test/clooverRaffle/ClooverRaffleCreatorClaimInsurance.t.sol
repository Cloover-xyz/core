// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/RaffleTest.sol";

contract ClooverRaffleCreatorClaimInsuranceTest is RaffleTest {
    using PercentageMath for uint256;

    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_CreatorClaimInsurance(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant1);
        uint16 max = raffle.ticketSalesInsurance();
        (uint256 ticketPurchased) = _purchaseRandomAmountOfTickets(raffle, participant1, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        uint256 totalSalesAmount = raffle.ticketPrice() * ticketPurchased;
        uint256 insurancePaid = raffle.insurancePaid();

        uint256 treasuryAmount = insurancePaid.percentMul(PROTOCOL_FEE_RATE);

        uint256 creatorBalanceBefore = address(creator).balance;
        uint256 expectedBalanceLeftOnContract = insurancePaid - treasuryAmount + totalSalesAmount;

        if (isEthRaffle) {
            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.CreatorClaimedInsurance();
            raffle.creatorClaimInsuranceInEth();
            assertEq(address(raffle).balance, expectedBalanceLeftOnContract);
            assertEq(address(treasury).balance, treasuryAmount);
            assertEq(address(creator).balance, creatorBalanceBefore);
        } else {
            creatorBalanceBefore = erc20Mock.balanceOf(creator);
            uint256 treasuryBalanceBefore = erc20Mock.balanceOf(treasury);
            vm.expectEmit(true, true, true, true);
            emit ClooverRaffleEvents.CreatorClaimedInsurance();
            raffle.creatorClaimInsurance();
            assertEq(erc20Mock.balanceOf(address(raffle)), expectedBalanceLeftOnContract);
            assertEq(erc20Mock.balanceOf(treasury), treasuryBalanceBefore + treasuryAmount);
            assertEq(erc20Mock.balanceOf(address(creator)), creatorBalanceBefore);
        }

        assertEq(erc721Mock.ownerOf(nftId), creator);
    }

    function test_CreatorClaimInsurance_RevertWhen_AlreadyClaimed(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant1);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant1, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        if (isEthRaffle) {
            raffle.creatorClaimInsuranceInEth();
            vm.expectRevert();
            raffle.creatorClaimInsuranceInEth();
        } else {
            raffle.creatorClaimInsurance();
            vm.expectRevert();
            raffle.creatorClaimInsurance();
        }
    }

    function test_CreatorClaimInsurance_RevertWhen_NotCorrectTypeOfRaffle(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant1);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant1, max - 1);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);
        if (isEthRaffle) {
            vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
            raffle.creatorClaimInsurance();
        } else {
            vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
            raffle.creatorClaimInsuranceInEth();
        }
    }

    function test_CreatorClaimInsurance_RevertWhen_CreatorDidNotTookInsurance(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, false, false);

        changePrank(participant1);
        uint16 max = raffle.maxTotalSupply();
        _purchaseRandomAmountOfTickets(raffle, participant1, max);

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);
        vm.expectRevert(Errors.NO_INSURANCE_TAKEN.selector);
        if (isEthRaffle) {
            raffle.creatorClaimInsuranceInEth();
        } else {
            raffle.creatorClaimInsurance();
        }
    }

    function test_CreatorClaimInsurance_RevertWhen_NotCreatorCalling(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant1);
        uint16 max = raffle.ticketSalesInsurance();
        _purchaseRandomAmountOfTickets(raffle, participant1, max - 1);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.NOT_CREATOR.selector);
        if (isEthRaffle) {
            raffle.creatorClaimInsuranceInEth();
        } else {
            raffle.creatorClaimInsurance();
        }
    }

    function test_CreatorClaimInsurance_RevertWhen_NoTicketHaveBeenSold(bool isEthRaffle) external {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        if (isEthRaffle) {
            raffle.creatorClaimInsuranceInEth();
        } else {
            raffle.creatorClaimInsurance();
        }
    }

    function test_CreatorClaimInsurance_RevertWhen_TicketSalesAreEqualOrHigherThanInsurance(bool isEthRaffle)
        external
    {
        uint64 ticketSalesDuration;
        (raffle, ticketSalesDuration) = _createRandomRaffle(isEthRaffle, true, false);

        changePrank(participant1);

        _purchaseExactAmountOfTickets(raffle, participant1, raffle.ticketSalesInsurance());

        changePrank(creator);
        _forwardByTimestamp(ticketSalesDuration + 1);

        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        if (isEthRaffle) {
            raffle.creatorClaimInsuranceInEth();
        } else {
            raffle.creatorClaimInsurance();
        }
    }
}

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

    function test_UserClaimRefund() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            uint16 nbOfTicketsPurchased = initialTicketSalesInsurance - 1;

            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            uint256 totalSalesAmount = raffle.ticketPrice() * nbOfTicketsPurchased;
            (uint256 treasuryAmount, uint256 amountPerTicket) = initialTicketSalesInsurance.splitInsuranceAmount(
                INSURANCE_RATE, PROTOCOL_FEE_RATE, raffle.currentTicketSupply(), raffle.ticketPrice()
            );
            uint256 expectParticipantRefund = amountPerTicket * nbOfTicketsPurchased + totalSalesAmount;
            uint256 expectedRaffleBalanceLeft = treasuryAmount;
            uint256 parcipantBalanceBefore = address(participant).balance;

            if (isEthRaffle) {
                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.UserClaimedRefund(participant, expectParticipantRefund);
                raffle.claimParticipantRefundInEth();
                assertEq(address(raffle).balance, expectedRaffleBalanceLeft);
                assertEq(address(participant).balance, parcipantBalanceBefore + expectParticipantRefund);
            } else {
                parcipantBalanceBefore = erc20Mock.balanceOf(participant);
                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.UserClaimedRefund(participant, expectParticipantRefund);
                raffle.claimParticipantRefund();
                assertEq(erc20Mock.balanceOf(address(raffle)), expectedRaffleBalanceLeft);
                assertEq(erc20Mock.balanceOf(address(participant)), parcipantBalanceBefore + expectParticipantRefund);
            }
        }
    }

    function test_UserClaimRefund_RevertWhen_NotCorrectTypeOfRaffle() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            uint16 nbOfTicketsPurchased = initialTicketSalesInsurance - 1;

            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            if (isEthRaffle) {
                vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
                raffle.claimParticipantRefund();
            } else {
                vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
                raffle.claimParticipantRefundInEth();
            }
        }
    }

    function test_UserClaimRefund_RevertWhen_TicketSupplyGreaterThanMinInsuranceSales() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            uint16 nbOfTicketsPurchased = initialTicketSalesInsurance;

            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
            if (isEthRaffle) {
                raffle.claimParticipantRefundInEth();
            } else {
                raffle.claimParticipantRefund();
            }
        }
    }

    function test_UserClaimRefund_RevertWhen_UserAlreadyClaimedRefund() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            uint16 nbOfTicketsPurchased = initialTicketSalesInsurance - 1;

            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            if (isEthRaffle) {
                raffle.claimParticipantRefundInEth();
                vm.expectRevert(Errors.ALREADY_CLAIMED.selector);

                raffle.claimParticipantRefundInEth();
            } else {
                raffle.claimParticipantRefund();
                vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
                raffle.claimParticipantRefund();
            }
        }
    }

    function test_UserClaimRefund_RevertWhen_NothingToClaim() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            uint16 nbOfTicketsPurchased = initialTicketSalesInsurance - 1;

            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);
            changePrank(hacker);
            if (isEthRaffle) {
                vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
                raffle.claimParticipantRefundInEth();
            } else {
                vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
                raffle.claimParticipantRefund();
            }
        }
    }
}

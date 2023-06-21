// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleCreatorClaimInsuranceTest is IntegrationTest {
    using PercentageMath for uint256;

    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_CreatorClaimInsurance() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            uint16 nbOfTicketsPurchased = initialMinTicketThreshold - 1;

            _purchaseExactAmountOfTickets(raffle, participant, nbOfTicketsPurchased);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            uint256 totalSalesAmount = raffle.ticketPrice() * nbOfTicketsPurchased;
            uint256 insurancePaid = raffle.insurancePaid();
            uint256 treasuryAmount = insurancePaid.percentMul(PROTOCOL_FEE_RATE);
            uint256 expectedBalanceLeftOnContract = insurancePaid - treasuryAmount + totalSalesAmount;

            uint256 creatorBalanceBefore = address(creator).balance;
            uint256 treasuryBalanceBefore = address(treasury).balance;

            changePrank(creator);
            if (isEthRaffle) {
                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.CreatorClaimedRefund();
                raffle.claimCreatorRefundInEth();
                assertEq(address(raffle).balance, expectedBalanceLeftOnContract);
                assertEq(address(treasury).balance, treasuryBalanceBefore + treasuryAmount);
                assertEq(address(creator).balance, creatorBalanceBefore);
            } else {
                creatorBalanceBefore = erc20Mock.balanceOf(creator);
                treasuryBalanceBefore = erc20Mock.balanceOf(treasury);

                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.CreatorClaimedRefund();
                raffle.claimCreatorRefund();
                assertEq(erc20Mock.balanceOf(address(raffle)), expectedBalanceLeftOnContract);
                assertEq(erc20Mock.balanceOf(treasury), treasuryBalanceBefore + treasuryAmount);
                assertEq(erc20Mock.balanceOf(address(creator)), creatorBalanceBefore);
            }
            assertEq(erc721Mock.ownerOf(nftId), creator);
        }
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_AlreadyClaimed() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            _purchaseExactAmountOfTickets(raffle, participant, initialMinTicketThreshold - 1);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            changePrank(creator);
            if (isEthRaffle) {
                raffle.claimCreatorRefundInEth();
                vm.expectRevert();
                raffle.claimCreatorRefundInEth();
            } else {
                raffle.claimCreatorRefund();
                vm.expectRevert();
                raffle.claimCreatorRefund();
            }
        }
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_NotCorrectTypeOfRaffle() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            _purchaseExactAmountOfTickets(raffle, participant, initialMinTicketThreshold - 1);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            changePrank(creator);

            if (isEthRaffle) {
                vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
                raffle.claimCreatorRefund();
            } else {
                vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
                raffle.claimCreatorRefundInEth();
            }
        }
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_CreatorDidNotTookInsurance() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() != 0) continue;

            _purchaseExactAmountOfTickets(raffle, participant, initialMinTicketThreshold - 1);

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            changePrank(creator);
            vm.expectRevert(Errors.NO_INSURANCE_TAKEN.selector);
            if (isEthRaffle) {
                raffle.claimCreatorRefundInEth();
            } else {
                raffle.claimCreatorRefund();
            }
        }
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_NotCreatorCalling() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            _purchaseExactAmountOfTickets(raffle, participant, initialMinTicketThreshold - 1);

            _forwardByTimestamp(initialTicketSalesDuration + 1);
            changePrank(hacker);
            vm.expectRevert(Errors.NOT_CREATOR.selector);
            if (isEthRaffle) {
                raffle.claimCreatorRefundInEth();
            } else {
                raffle.claimCreatorRefund();
            }
        }
    }

    function test_CreatorClaimInsurance_TokenRaffle_RevertWhen_NoTicketHaveBeenSold() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);

            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            changePrank(creator);
            vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
            if (isEthRaffle) {
                raffle.claimCreatorRefundInEth();
            } else {
                raffle.claimCreatorRefund();
            }
        }
    }

    function test_CreatorClaimInsurance_RevertWhen_TicketSalesAreEqualOrHigherThanInsurance() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.minTicketThreshold() == 0) continue;

            changePrank(participant);
            _purchaseExactAmountOfTickets(raffle, participant, raffle.minTicketThreshold());

            _forwardByTimestamp(initialTicketSalesDuration + 1);

            changePrank(creator);
            vm.expectRevert(Errors.SALES_EXCEED_MIN_THRESHOLD_LIMIT.selector);
            if (isEthRaffle) {
                raffle.claimCreatorRefundInEth();
            } else {
                raffle.claimCreatorRefund();
            }
        }
    }
}

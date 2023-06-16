// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRafflePurchaseTicketsTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(creator);
    }

    function test_PurchaseTickets() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            uint256 amount = initialTicketPrice * nbOfTicketsPurchased;
            if (isEthRaffle) {
                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.TicketsPurchased(participant, 0, nbOfTicketsPurchased);
                raffle.purchaseTicketsInEth{value: amount}(nbOfTicketsPurchased);
            } else {
                _setERC20Balances(address(erc20Mock), participant, amount * 2);
                // classic
                erc20Mock.approve(address(raffle), amount);
                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.TicketsPurchased(participant, 0, nbOfTicketsPurchased);
                raffle.purchaseTickets(nbOfTicketsPurchased);

                // with permit
                uint256 privateKey = 6;
                ClooverRaffleTypes.PermitDataParams memory permitData =
                    _signPermitData(privateKey, address(raffle), amount);
                vm.expectEmit(true, true, true, true);
                emit ClooverRaffleEvents.TicketsPurchased(participant, 5, nbOfTicketsPurchased);
                raffle.purchaseTicketsWithPermit(nbOfTicketsPurchased, permitData);

                // setup for assertEq
                nbOfTicketsPurchased = 10;
            }
            assertEq(raffle.getParticipantTicketsNumber(participant).length, nbOfTicketsPurchased);
            assertEq(raffle.currentSupply(), nbOfTicketsPurchased);
        }
    }

    function test_PurchaseTickets_RevertWhen_NotCorrectTypeOfRaffle() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            if (isEthRaffle) {
                vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
                raffle.purchaseTickets(1);
            } else {
                vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
                raffle.purchaseTicketsInEth(1);
            }
        }
    }

    function test_PurchaseTickets_RevertWhen_AmountPurchaseIsZero() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);

            changePrank(participant);
            vm.expectRevert(Errors.CANT_BE_ZERO.selector);
            if (isEthRaffle) {
                raffle.purchaseTicketsInEth(0);
            } else {
                raffle.purchaseTickets(0);
            }
        }
    }

    function test_PurchaseTickets_RevertWhen_NbOfTicketPurchasedExceedMaxAmountOfTicketAllowedToPurchase() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.maxTicketAllowedToPurchase() == 0) continue;

            changePrank(participant);

            uint16 nbOfTicketsPurchased = raffle.maxTicketAllowedToPurchase() + 1;
            uint256 amount = initialTicketPrice * nbOfTicketsPurchased;
            if (isEthRaffle) {
                vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
                raffle.purchaseTicketsInEth{value: amount}(nbOfTicketsPurchased);
            } else {
                _setERC20Balances(address(erc20Mock), participant, amount * 2);
                // classic
                erc20Mock.approve(address(raffle), amount);
                vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
                raffle.purchaseTickets(nbOfTicketsPurchased);

                // with permit
                uint256 privateKey = 6;
                ClooverRaffleTypes.PermitDataParams memory permitData =
                    _signPermitData(privateKey, address(raffle), amount);
                vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
                raffle.purchaseTicketsWithPermit(nbOfTicketsPurchased, permitData);
            }
        }
    }

    function test_PurchaseTickets_RevertWhen_NbOfTicketPurchasedMakeCurrentSupplyExceedMaxSupply() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.maxTicketAllowedToPurchase() != 0) continue;

            changePrank(participant);

            uint16 nbOfTicketsPurchased = raffle.maxTotalSupply() + 1;
            uint256 amount = initialTicketPrice * nbOfTicketsPurchased;
            if (isEthRaffle) {
                vm.expectRevert(Errors.TICKET_SUPPLY_OVERFLOW.selector);
                raffle.purchaseTicketsInEth{value: amount}(nbOfTicketsPurchased);
            } else {
                _setERC20Balances(address(erc20Mock), participant, amount * 2);
                // classic
                erc20Mock.approve(address(raffle), amount);
                vm.expectRevert(Errors.TICKET_SUPPLY_OVERFLOW.selector);
                raffle.purchaseTickets(nbOfTicketsPurchased);

                // with permit
                uint256 privateKey = 6;
                ClooverRaffleTypes.PermitDataParams memory permitData =
                    _signPermitData(privateKey, address(raffle), amount);
                vm.expectRevert(Errors.TICKET_SUPPLY_OVERFLOW.selector);
                raffle.purchaseTicketsWithPermit(nbOfTicketsPurchased, permitData);
            }
        }
    }

    function test_PurchaseTickets_EthRaffle_RevertWhen_ValueSentIsNotEqualToTicketsCost() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (!isEthRaffle) continue;

            changePrank(participant);
            uint16 nbOfTicketsPurchased = 5;
            uint256 amount = initialTicketPrice * nbOfTicketsPurchased;

            vm.expectRevert(Errors.WRONG_MSG_VALUE.selector);
            raffle.purchaseTicketsInEth{value: amount + 1}(nbOfTicketsPurchased);

            vm.expectRevert(Errors.WRONG_MSG_VALUE.selector);
            raffle.purchaseTicketsInEth{value: amount - 1}(nbOfTicketsPurchased);
        }
    }

    function test_PurchaseTickets_TokenRaffle_RevertWhen_TicketSalesOver() external {
        for (uint256 i; i < rafflesArray.length; i++) {
            _setBlockTimestamp(blockTimestamp);
            RaffleArrayInfo memory raffleInfo = rafflesArray[i];
            (isEthRaffle, nftId, raffle) = (raffleInfo.isEthRaffle, raffleInfo.nftId, raffleInfo.raffle);
            if (raffle.maxTicketAllowedToPurchase() == 0) continue;

            changePrank(participant);

            uint16 nbOfTicketsPurchased = raffle.maxTicketAllowedToPurchase() + 1;
            uint256 amount = initialTicketPrice * nbOfTicketsPurchased;
            _forwardByTimestamp(initialTicketSalesDuration + 1);
            if (isEthRaffle) {
                vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
                raffle.purchaseTicketsInEth{value: amount}(nbOfTicketsPurchased);
            } else {
                _setERC20Balances(address(erc20Mock), participant, amount * 2);
                // classic
                erc20Mock.approve(address(raffle), amount);
                vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
                raffle.purchaseTickets(nbOfTicketsPurchased);

                // with permit
                uint256 privateKey = 6;
                ClooverRaffleTypes.PermitDataParams memory permitData =
                    _signPermitData(privateKey, address(raffle), amount);
                vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
                raffle.purchaseTicketsWithPermit(nbOfTicketsPurchased, permitData);
            }
        }
    }
}

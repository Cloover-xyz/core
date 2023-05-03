// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {ClooverRaffle} from "../../../src/raffle/ClooverRaffle.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ClooverRaffleDataTypes} from "../../../src/libraries/types/ClooverRaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract PurchaseTicketsClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();
    }

    function test_PurchaseTickets() external{
        changePrank(bob);

        mockERC20.approve(address(tokenRaffle), 100e18);

        tokenRaffle.purchaseTickets(1);

        assertEq(tokenRaffle.ownerOf(0), address(0));
        assertEq(tokenRaffle.ownerOf(1), bob);
        uint16[] memory bobTickets = tokenRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 1);
        assertEq(bobTickets[0], 1);
        assertEq(tokenRaffle.currentSupply(), 1);
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), ticketPrice);
    }

    function test_PurchaseTickets_SeveralTimes() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e18);
        tokenRaffle.purchaseTickets(1);
        tokenRaffle.purchaseTickets(9);

        assertEq(tokenRaffle.ownerOf(0), address(0));
        assertEq(tokenRaffle.ownerOf(1), bob);
        assertEq(tokenRaffle.ownerOf(10), bob);
        uint16[] memory bobTickets = tokenRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(tokenRaffle.currentSupply(), 10);
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), ticketPrice * 10);
    }

    function test_PurchaseTickets_RevertWhen_NewPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.TICKET_SUPPLY_OVERFLOW.selector);
        tokenRaffle.purchaseTickets(11);
    }

    function test_PurchaseTickets_RevertWhen_UserNotHaveEnoughBalance() external{
        changePrank(alice);
        vm.expectRevert("ERC20: insufficient allowance");
        tokenRaffle.purchaseTickets(1);
    }

    function test_PurchaseTickets_RevertWhen_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        tokenRaffle.purchaseTickets(0);
    }

    function test_PurchaseTickets_RevertWhen_UserTicketBalanceExceedLimitAllowed() external{
        changePrank(alice);
        uint256 _nftId = 50;
        mockERC721.mint(alice, _nftId);
        ClooverRaffle raffleLimit = new ClooverRaffle();
        ClooverRaffleDataTypes.InitializeRaffleParams memory ethData = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: mockERC20,
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 5,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        mockERC721.transferFrom(alice, address(raffleLimit), _nftId);
        raffleLimit.initialize(ethData);

        changePrank(bob);
        mockERC20.approve(address(raffleLimit), 100e18);
        raffleLimit.purchaseTickets(4);
        vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
        raffleLimit.purchaseTickets(5);
    }

    function test_PurchaseTickets_RevertWhen_IsEthClooverRaffle() external{      
        changePrank(bob);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.purchaseTickets(1);
    }

    function test_PurchaseTickets_RevertWhen_TicketSalesClose() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        tokenRaffle.purchaseTickets(1);
    }

    function test_PurchaseTicketsInEth() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice}(1);

        assertEq(ethRaffle.ownerOf(0), address(0));
        assertEq(ethRaffle.ownerOf(1), bob);
        uint16[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 1);
        assertEq(bobTickets[0], 1);
        assertEq(ethRaffle.currentSupply(), 1);
        assertEq(address(ethRaffle).balance, ticketPrice);
    }

    function test_PurchaseTicketsInEth_SeveralTimes() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice}(1);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice * 9}(9);

        assertEq(ethRaffle.ownerOf(0), address(0));
        assertEq(ethRaffle.ownerOf(1), bob);
        assertEq(ethRaffle.ownerOf(10), bob);
        uint16[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(ethRaffle.currentSupply(), 10);
        assertEq(address(ethRaffle).balance, ticketPrice * 10);
    }

    function test_PurchaseTicketsInEth_SeveralTickets() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice * 10}(10);

        assertEq(ethRaffle.ownerOf(0), address(0));
        assertEq(ethRaffle.ownerOf(1), bob);
        assertEq(ethRaffle.ownerOf(10), bob);
        uint16[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(ethRaffle.currentSupply(), 10);
        assertEq(address(ethRaffle).balance, ticketPrice * 10);
    }

    function test_PurchaseTicketsInEth_RevertWhen_NewPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.TICKET_SUPPLY_OVERFLOW.selector);
        ethRaffle.purchaseTicketsInEth{value: 11e18}(11);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserSendWrongAmountOfEthForPurchase() external{
        changePrank(alice);
        vm.expectRevert(Errors.WRONG_MSG_VALUE.selector);
        ethRaffle.purchaseTicketsInEth{value: 1e19}(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        ethRaffle.purchaseTicketsInEth(0);
    }

    function test_PurchaseTicketsInEth_RevertWhen_NotEthClooverRaffle() external{
        changePrank(bob);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.purchaseTicketsInEth(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_TicketSalesClose() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice}(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserTicketPurchaseExceedLimitAllowed() external{
        changePrank(alice);
        uint256 _nftId = 50;
        mockERC721.mint(alice, _nftId);
        ClooverRaffle ethRaffleLimit = new ClooverRaffle();
        ClooverRaffleDataTypes.InitializeRaffleParams memory ethData = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 5,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        mockERC721.transferFrom(alice, address(ethRaffleLimit), _nftId);
        ethRaffleLimit.initialize(ethData);

        changePrank(bob);
        ethRaffleLimit.purchaseTicketsInEth{value: ticketPrice * 4}(4);
        vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
        ethRaffleLimit.purchaseTicketsInEth{value: ticketPrice * 5}(5);
    }

}
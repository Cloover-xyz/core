// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {Raffle} from "../../../src/raffle/Raffle.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {RaffleDataTypes} from "../../../src/libraries/types/RaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupRaffles} from "./SetupRaffles.sol";

contract PurchaseTicketsRaffleTest is Test, SetupRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupRaffles.setUp();
    }

    function test_PurchaseTickets() external{
        changePrank(bob);

        mockERC20.approve(address(tokenRaffle), 100e18);

        tokenRaffle.purchaseTickets(1);

        assertEq(tokenRaffle.ownerOf(0), address(0));
        assertEq(tokenRaffle.ownerOf(1), bob);
        uint256[] memory bobTickets = tokenRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 1);
        assertEq(bobTickets[0], 1);
        assertEq(tokenRaffle.totalSupply(), 1);
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
        uint256[] memory bobTickets = tokenRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(tokenRaffle.totalSupply(), 10);
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), ticketPrice * 10);
    }

    function test_PurchaseTickets_RevertWhen_NewPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
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
        mockERC721.mint(alice, 3);
        Raffle raffleLimit = new Raffle();
        RaffleDataTypes.InitRaffleParams memory ethData = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            3,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            false,
            5
        );
        mockERC721.transferFrom(alice, address(raffleLimit), 3);
        raffleLimit.initialize(ethData);

        changePrank(bob);
        mockERC20.approve(address(raffleLimit), 100e18);
        raffleLimit.purchaseTickets(4);
        vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
        raffleLimit.purchaseTickets(5);
    }

    function test_PurchaseTickets_RevertWhen_IsEthRaffle() external{      
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
        uint256[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 1);
        assertEq(bobTickets[0], 1);
        assertEq(ethRaffle.totalSupply(), 1);
        assertEq(address(ethRaffle).balance, ticketPrice);
    }

    function test_PurchaseTicketsInEth_SeveralTimes() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice}(1);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice * 9}(9);

        assertEq(ethRaffle.ownerOf(0), address(0));
        assertEq(ethRaffle.ownerOf(1), bob);
        assertEq(ethRaffle.ownerOf(10), bob);
        uint256[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(ethRaffle.totalSupply(), 10);
        assertEq(address(ethRaffle).balance, ticketPrice * 10);
    }

    function test_PurchaseTicketsInEth_SeveralTickets() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice * 10}(10);

        assertEq(ethRaffle.ownerOf(0), address(0));
        assertEq(ethRaffle.ownerOf(1), bob);
        assertEq(ethRaffle.ownerOf(10), bob);
        uint256[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(ethRaffle.totalSupply(), 10);
        assertEq(address(ethRaffle).balance, ticketPrice * 10);
    }

    function test_PurchaseTicketsInEth_RevertWhen_NewPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
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

    function test_PurchaseTicketsInEth_RevertWhen_NotEthRaffle() external{
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
        mockERC721.mint(alice, 3);
        Raffle ethRaffleLimit = new Raffle();
        RaffleDataTypes.InitRaffleParams memory ethData = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            3,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            true,
            5
        );
        mockERC721.transferFrom(alice, address(ethRaffleLimit), 3);
        ethRaffleLimit.initialize(ethData);

        changePrank(bob);
        ethRaffleLimit.purchaseTicketsInEth{value: ticketPrice * 4}(4);
        vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
        ethRaffleLimit.purchaseTicketsInEth{value: ticketPrice * 5}(5);
    }

}
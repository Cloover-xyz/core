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

        mockERC20.approve(address(tokenClooverRaffle), 100e18);

        tokenClooverRaffle.purchaseTickets(1);

        assertEq(tokenClooverRaffle.ownerOf(0), address(0));
        assertEq(tokenClooverRaffle.ownerOf(1), bob);
        uint256[] memory bobTickets = tokenClooverRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 1);
        assertEq(bobTickets[0], 1);
        assertEq(tokenClooverRaffle.totalSupply(), 1);
        assertEq(mockERC20.balanceOf(address(tokenClooverRaffle)), ticketPrice);
    }

    function test_PurchaseTickets_SeveralTimes() external{
        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffle), 100e18);
        tokenClooverRaffle.purchaseTickets(1);
        tokenClooverRaffle.purchaseTickets(9);

        assertEq(tokenClooverRaffle.ownerOf(0), address(0));
        assertEq(tokenClooverRaffle.ownerOf(1), bob);
        assertEq(tokenClooverRaffle.ownerOf(10), bob);
        uint256[] memory bobTickets = tokenClooverRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(tokenClooverRaffle.totalSupply(), 10);
        assertEq(mockERC20.balanceOf(address(tokenClooverRaffle)), ticketPrice * 10);
    }

    function test_PurchaseTickets_RevertWhen_NewPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
        tokenClooverRaffle.purchaseTickets(11);
    }

    function test_PurchaseTickets_RevertWhen_UserNotHaveEnoughBalance() external{
        changePrank(alice);
        vm.expectRevert("ERC20: insufficient allowance");
        tokenClooverRaffle.purchaseTickets(1);
    }

    function test_PurchaseTickets_RevertWhen_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        tokenClooverRaffle.purchaseTickets(0);
    }

    function test_PurchaseTickets_RevertWhen_UserTicketBalanceExceedLimitAllowed() external{
        changePrank(alice);
        uint256 _nftId = 50;
        mockERC721.mint(alice, _nftId);
        ClooverRaffle raffleLimit = new ClooverRaffle();
        ClooverRaffleDataTypes.InitClooverRaffleParams memory ethData = ClooverRaffleDataTypes.InitClooverRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            false,
            5,
            0
        );
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
        ethClooverRaffle.purchaseTickets(1);
    }

    function test_PurchaseTickets_RevertWhen_TicketSalesClose() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        tokenClooverRaffle.purchaseTickets(1);
    }

    function test_PurchaseTicketsInEth() external{
        changePrank(bob);
        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice}(1);

        assertEq(ethClooverRaffle.ownerOf(0), address(0));
        assertEq(ethClooverRaffle.ownerOf(1), bob);
        uint256[] memory bobTickets = ethClooverRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 1);
        assertEq(bobTickets[0], 1);
        assertEq(ethClooverRaffle.totalSupply(), 1);
        assertEq(address(ethClooverRaffle).balance, ticketPrice);
    }

    function test_PurchaseTicketsInEth_SeveralTimes() external{
        changePrank(bob);
        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice}(1);
        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice * 9}(9);

        assertEq(ethClooverRaffle.ownerOf(0), address(0));
        assertEq(ethClooverRaffle.ownerOf(1), bob);
        assertEq(ethClooverRaffle.ownerOf(10), bob);
        uint256[] memory bobTickets = ethClooverRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(ethClooverRaffle.totalSupply(), 10);
        assertEq(address(ethClooverRaffle).balance, ticketPrice * 10);
    }

    function test_PurchaseTicketsInEth_SeveralTickets() external{
        changePrank(bob);
        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice * 10}(10);

        assertEq(ethClooverRaffle.ownerOf(0), address(0));
        assertEq(ethClooverRaffle.ownerOf(1), bob);
        assertEq(ethClooverRaffle.ownerOf(10), bob);
        uint256[] memory bobTickets = ethClooverRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(ethClooverRaffle.totalSupply(), 10);
        assertEq(address(ethClooverRaffle).balance, ticketPrice * 10);
    }

    function test_PurchaseTicketsInEth_RevertWhen_NewPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
        ethClooverRaffle.purchaseTicketsInEth{value: 11e18}(11);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserSendWrongAmountOfEthForPurchase() external{
        changePrank(alice);
        vm.expectRevert(Errors.WRONG_MSG_VALUE.selector);
        ethClooverRaffle.purchaseTicketsInEth{value: 1e19}(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        ethClooverRaffle.purchaseTicketsInEth(0);
    }

    function test_PurchaseTicketsInEth_RevertWhen_NotEthClooverRaffle() external{
        changePrank(bob);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenClooverRaffle.purchaseTicketsInEth(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_TicketSalesClose() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice}(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserTicketPurchaseExceedLimitAllowed() external{
        changePrank(alice);
        uint256 _nftId = 50;
        mockERC721.mint(alice, _nftId);
        ClooverRaffle ethClooverRaffleLimit = new ClooverRaffle();
        ClooverRaffleDataTypes.InitClooverRaffleParams memory ethData = ClooverRaffleDataTypes.InitClooverRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            true,
            5,
            0
        );
        mockERC721.transferFrom(alice, address(ethClooverRaffleLimit), _nftId);
        ethClooverRaffleLimit.initialize(ethData);

        changePrank(bob);
        ethClooverRaffleLimit.purchaseTicketsInEth{value: ticketPrice * 4}(4);
        vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
        ethClooverRaffleLimit.purchaseTicketsInEth{value: ticketPrice * 5}(5);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";
import {PercentageMath} from "../../../src/libraries/math/PercentageMath.sol";

import {SetupRaffles} from "./SetupRaffles.sol";

contract CreatorClaimTicketSalesRaffleTest is Test, SetupRaffles {
    using InsuranceLogic for uint;
    using PercentageMath for uint;

    function setUp() public virtual override {
        SetupRaffles.setUp();

        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e18);
        tokenRaffle.purchaseTickets(2);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice * 2}(2);
    }
    
    function test_CreatorClaimTicketSales() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 aliceBalanceBefore = mockERC20.balanceOf(alice);
        uint256 treasuryBalanceBefore = mockERC20.balanceOf(treasury);
        uint256 totalSalesAmount = ticketPrice * 2;
        tokenRaffle.creatorClaimTicketSales();
        assertEq(mockERC20.balanceOf(treasury), treasuryBalanceBefore + totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(mockERC20.balanceOf(alice), aliceBalanceBefore + totalSalesAmount - totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 0);
    }

    function test_CreatorClaimTicketSales_RevertWhen_IsEthRaffle() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.creatorClaimTicketSales();
    }

    function test_CreatorClaimTicketSales_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenRaffle.creatorClaimTicketSales();
    }

    function test_CreatorClaimTicketSales_RevertWhen_WinningTicketNotDrawn() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        tokenRaffle.creatorClaimTicketSales();
    }

    function test_CreatorClaimTicketSalesInEth() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 aliceBalanceBefore = address(alice).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        uint256 totalSalesAmount = ticketPrice * 2;
        ethRaffle.creatorClaimTicketSalesInEth();
        assertEq(address(treasury).balance, treasuryBalanceBefore + totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(address(alice).balance, aliceBalanceBefore + totalSalesAmount - totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(address(ethRaffle).balance, 0);
    }

    function test_CreatorClaimTicketSalesInEth_RevertWhen_NotEthRaffle() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.creatorClaimTicketSalesInEth();
    }

    function test_CreatorClaimTicketSalesInEth_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethRaffle.creatorClaimTicketSalesInEth();
    }

    function test_CreatorClaimTicketSalesInEth_RevertWhen_WinningTicketNotDrawn() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        changePrank(alice);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        ethRaffle.creatorClaimTicketSalesInEth();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";
import {PercentageMath} from "../../../src/libraries/math/PercentageMath.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract CreatorClaimTicketSalesClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;
    using PercentageMath for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();

        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffle), 100e18);
        tokenClooverRaffle.purchaseTickets(2);
        mockERC20.approve(address(tokenClooverRaffleWithRoyalties), 100e18);
        tokenClooverRaffleWithRoyalties.purchaseTickets(2);

        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice * 2}(2);
        ethClooverRaffleWithRoyalties.purchaseTicketsInEth{value: ticketPrice * 2}(2);
    }
    
    function test_CreatorClaimTicketSales() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 aliceBalanceBefore = mockERC20.balanceOf(alice);
        uint256 treasuryBalanceBefore = mockERC20.balanceOf(treasury);
        uint256 totalSalesAmount = ticketPrice * 2;
        tokenClooverRaffle.creatorClaimTicketSales();
        assertEq(mockERC20.balanceOf(treasury), treasuryBalanceBefore + totalSalesAmount.percentMul(PROTOCOL_FEES_PERCENTAGE));
        assertEq(mockERC20.balanceOf(alice), aliceBalanceBefore + totalSalesAmount - totalSalesAmount.percentMul(PROTOCOL_FEES_PERCENTAGE));
        assertEq(mockERC20.balanceOf(address(tokenClooverRaffle)), 0);
    }

    function test_CreatorClaimTicketSales_WithRoyalties() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffleWithRoyalties.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffleWithRoyalties));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 nftCollectionCreatorBalanceBefore = mockERC20.balanceOf(admin);
        uint256 aliceBalanceBefore = mockERC20.balanceOf(alice);
        uint256 treasuryBalanceBefore = mockERC20.balanceOf(treasury);
        uint256 totalSalesAmount = ticketPrice * 2;
        tokenClooverRaffleWithRoyalties.creatorClaimTicketSales();
        uint256 protocolFees = totalSalesAmount.percentMul(
            PROTOCOL_FEES_PERCENTAGE
        );
        uint256 royaltiesAmount = totalSalesAmount.percentMul(
            royaltiesPercentage
        );
        assertEq(mockERC20.balanceOf(treasury), treasuryBalanceBefore + protocolFees);
        assertEq(mockERC20.balanceOf(admin), nftCollectionCreatorBalanceBefore + royaltiesAmount);
        assertEq(mockERC20.balanceOf(alice), aliceBalanceBefore + totalSalesAmount - protocolFees - royaltiesAmount);
        assertEq(mockERC20.balanceOf(address(tokenClooverRaffleWithRoyalties)), 0);
    }

    function test_CreatorClaimTicketSales_RevertWhen_IsEthClooverRaffle() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethClooverRaffle.creatorClaimTicketSales();
    }

    function test_CreatorClaimTicketSales_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenClooverRaffle.creatorClaimTicketSales();
    }

    function test_CreatorClaimTicketSales_RevertWhen_WinningTicketNotDrawn() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        tokenClooverRaffle.creatorClaimTicketSales();
    }

    function test_CreatorClaimTicketSalesInEth() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 aliceBalanceBefore = address(alice).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        uint256 totalSalesAmount = ticketPrice * 2;
        ethClooverRaffle.creatorClaimTicketSalesInEth();
        assertEq(address(treasury).balance, treasuryBalanceBefore + totalSalesAmount.percentMul(PROTOCOL_FEES_PERCENTAGE));
        assertEq(address(alice).balance, aliceBalanceBefore + totalSalesAmount - totalSalesAmount.percentMul(PROTOCOL_FEES_PERCENTAGE));
        assertEq(address(ethClooverRaffle).balance, 0);
    }

    function test_CreatorClaimTicketSalesInEth_WithRoyalties() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffleWithRoyalties.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffleWithRoyalties));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 nftCollectionCreatorBalanceBefore = address(admin).balance;
        uint256 aliceBalanceBefore = address(alice).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        uint256 totalSalesAmount = ticketPrice * 2;
        ethClooverRaffleWithRoyalties.creatorClaimTicketSalesInEth();
        uint256 protocolFees = totalSalesAmount.percentMul(
            PROTOCOL_FEES_PERCENTAGE
        );
        uint256 royaltiesAmount = totalSalesAmount.percentMul(
            royaltiesPercentage
        );
        assertEq(address(treasury).balance, treasuryBalanceBefore + protocolFees);
        assertEq(address(admin).balance, nftCollectionCreatorBalanceBefore + royaltiesAmount);
        assertEq(address(alice).balance, aliceBalanceBefore + totalSalesAmount - protocolFees - royaltiesAmount);
        assertEq(address(tokenClooverRaffleWithRoyalties).balance, 0);
    }

    function test_CreatorClaimTicketSalesInEth_RevertWhen_NotEthClooverRaffle() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenClooverRaffle.creatorClaimTicketSalesInEth();
    }

    function test_CreatorClaimTicketSalesInEth_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethClooverRaffle.creatorClaimTicketSalesInEth();
    }

    function test_CreatorClaimTicketSalesInEth_RevertWhen_WinningTicketNotDrawn() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        changePrank(alice);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        ethClooverRaffle.creatorClaimTicketSalesInEth();
    }
}
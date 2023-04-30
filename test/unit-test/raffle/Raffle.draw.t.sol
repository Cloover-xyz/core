// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {RaffleDataTypes} from "../../../src/libraries/types/RaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupRaffles} from "./SetupRaffles.sol";

contract DrawRaffleTest is Test, SetupRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupRaffles.setUp();

        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e18);
        tokenRaffle.purchaseTickets(2);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice * 2}(2);
    }

    function test_Draw_TokenRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(tokenRaffle.winnerAddress() == address(0));
        assertTrue(tokenRaffle.winnerAddress() == bob);
    }

    function test_Draw_TokenRaffle_RevertWhen_TicketSalesStillOpen() external{
        changePrank(bob);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        tokenRaffle.draw();
    }

    function test_Draw_TokenRaffle_StatusBackToInitWhenRandomNumberTicketDrawnedIsZero() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.requestRandomNumberReturnZero(requestId);
        assertTrue(tokenRaffle.raffleStatus() == RaffleDataTypes.RaffleStatus.Init);
    }

    function test_Draw_StatusSetToRefundWhenTicketSoldAmountUnderInsuranceAmount() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e18);
        tokenRaffleWithInsurance.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffleWithInsurance.draw();
        assertTrue(tokenRaffleWithInsurance.raffleStatus() == RaffleDataTypes.RaffleStatus.RefundMode);
    }

    function test_Draw_TokenRaffle_RevertWhen_TicketAlreadyDrawn() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
        tokenRaffle.draw();
    }

    function test_Draw_EthRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(ethRaffle.winnerAddress() == address(0));
        assertTrue(ethRaffle.winnerAddress() == bob);
    }

    function test_Draw_EthRaffle_RevertWhen_TicketSalesStillOpen() external{
        changePrank(bob);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        ethRaffle.draw();
    }

    function test_Draw_EthRaffle_StatusBackToInitWhenRandomNumberTicketDrawnedIsZero() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.requestRandomNumberReturnZero(requestId);
        assertTrue(ethRaffle.raffleStatus() == RaffleDataTypes.RaffleStatus.Init);
    }

    function test_Draw_EthRaffle_RevertWhen_TicketAlreadyDrawn() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
        ethRaffle.draw();
    }

    function test_Draw_StatusSetToRefundWhenNoTicketSoldAfterOpenWindows() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffleWithInsurance.draw();
        assertTrue(tokenRaffleWithInsurance.raffleStatus() == RaffleDataTypes.RaffleStatus.RefundMode);
    }
}
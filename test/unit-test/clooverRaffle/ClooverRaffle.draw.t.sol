// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ClooverRaffleDataTypes} from "../../../src/libraries/types/ClooverRaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract DrawClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();

        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffle), 100e18);
        tokenClooverRaffle.purchaseTickets(2);
        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice * 2}(2);
    }

    function test_Draw_TokenClooverRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(tokenClooverRaffle.winnerAddress() == address(0));
        assertTrue(tokenClooverRaffle.winnerAddress() == bob);
    }

    function test_Draw_TokenClooverRaffle_RevertWhen_TicketSalesStillOpen() external{
        changePrank(bob);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        tokenClooverRaffle.draw();
    }

    function test_Draw_TokenClooverRaffle_StatusBackToInitWhenRandomNumberTicketDrawnedIsZero() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffle));
        mockRamdomProvider.requestRandomNumberReturnZero(requestId);
        assertTrue(tokenClooverRaffle.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DEFAULT);
    }

    function test_Draw_StatusSetToRefundWhenTicketSoldAmountUnderInsuranceAmount() external{
        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffleWithInsurance), 100e18);
        tokenClooverRaffleWithInsurance.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffleWithInsurance.draw();
        assertTrue(tokenClooverRaffleWithInsurance.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.INSURANCE);
    }

    function test_Draw_TokenClooverRaffle_RevertWhen_TicketAlreadyDrawn() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
        tokenClooverRaffle.draw();
    }

    function test_Draw_EthClooverRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(ethClooverRaffle.winnerAddress() == address(0));
        assertTrue(ethClooverRaffle.winnerAddress() == bob);
    }

    function test_Draw_EthClooverRaffle_RevertWhen_TicketSalesStillOpen() external{
        changePrank(bob);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        ethClooverRaffle.draw();
    }

    function test_Draw_EthClooverRaffle_StatusBackToInitWhenRandomNumberTicketDrawnedIsZero() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffle));
        mockRamdomProvider.requestRandomNumberReturnZero(requestId);
        assertTrue(ethClooverRaffle.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DEFAULT);
    }

    function test_Draw_EthClooverRaffle_RevertWhen_TicketAlreadyDrawn() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
        ethClooverRaffle.draw();
    }

    function test_Draw_StatusSetToRefundWhenNoTicketSoldAfterOpenWindows() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffleWithInsurance.draw();
        assertTrue(tokenClooverRaffleWithInsurance.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.INSURANCE);
    }
}
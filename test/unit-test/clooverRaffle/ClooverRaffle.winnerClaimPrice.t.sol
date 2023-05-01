// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";

import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract WinnerClaimClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();

        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffle), 100e18);
        tokenClooverRaffle.purchaseTickets(2);
        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice * 2}(2);
    }

    function test_WinnerClaim_TokenClooverRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 winningTicketNumber = 1;
        vm.store(address(tokenClooverRaffle),bytes32(uint256(12)), bytes32(winningTicketNumber));
        assertEq(tokenClooverRaffle.winningTicket(), winningTicketNumber);
        tokenClooverRaffle.winnerClaim();
        assertEq(mockERC721.ownerOf(tokenNftId),bob);
        assertEq(tokenClooverRaffle.winnerAddress(), bob);
    }

    function test_WinnerClaim_TokenClooverRaffle_RevertWhen_ClooverRaffleStillOpen() external{
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        tokenClooverRaffle.winnerClaim();
    }

    function test_WinnerClaim_TokenClooverRaffle_RevertWhen_NotWinnerTryToClaimPrice() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        tokenClooverRaffle.winnerClaim();
    }

    function test_WinnerClaim_TokenClooverRaffle_RevertWhen_DrawnHasNotBeDone() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        tokenClooverRaffle.winnerClaim();
    }

    function test_WinnerClaim_EthClooverRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 winningTicketNumber = 1;
        vm.store(address(ethClooverRaffle),bytes32(uint256(12)), bytes32(winningTicketNumber));
        assertEq(ethClooverRaffle.winningTicket(), winningTicketNumber);
        ethClooverRaffle.winnerClaim();
        assertEq(mockERC721.ownerOf(ethNftId),bob);
        assertEq(ethClooverRaffle.winnerAddress(), bob);
    }

    function test_WinnerClaim_EthClooverRaffle_RevertWhen_ClooverRaffleStillOpen() external{
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        ethClooverRaffle.winnerClaim();
    }

    function test_WinnerClaim_EthClooverRaffle_RevertWhen_NotWinnerTryToClaimPrice() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethClooverRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        ethClooverRaffle.winnerClaim();
    }

    function test_WinnerClaim_EthClooverRaffle_RevertWhen_DrawnHasNotBeDone() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        ethClooverRaffle.winnerClaim();
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";

import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract WinnerClaimClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();

        changePrank(bob);
        mockERC20WithPermit.approve(address(tokenRaffle), 100e18);
        tokenRaffle.purchaseTickets(2);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice * 2}(2);
    }

    function test_WinnerClaim_TokenRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(tokenRaffle.winningTicket() == 0);
        assertFalse(tokenRaffle.winningTicket() > tokenRaffle.currentSupply());
        tokenRaffle.winnerClaim();
        assertEq(mockERC721.ownerOf(tokenNftId),bob);
        assertEq(tokenRaffle.winnerAddress(), bob);
    }

    function test_WinnerClaim_TokenRaffle_RevertWhen_NotWinnerTryToClaimPrice() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        tokenRaffle.winnerClaim();
    }

    function test_WinnerClaim_TokenRaffle_RevertWhen_DrawnHasNotBeDone() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        tokenRaffle.winnerClaim();
    }

    function test_WinnerClaim_EthRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(ethRaffle.winningTicket() == 0);
        assertFalse(ethRaffle.winningTicket() > ethRaffle.currentSupply());
        ethRaffle.winnerClaim();
        assertEq(mockERC721.ownerOf(ethNftId),bob);
        assertEq(ethRaffle.winnerAddress(), bob);
    }

    function test_WinnerClaim_EthRaffle_RevertWhen_NotWinnerTryToClaimPrice() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.draw();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        ethRaffle.winnerClaim();
    }

    function test_WinnerClaim_EthRaffle_RevertWhen_DrawnHasNotBeDone() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        ethRaffle.winnerClaim();
    }
}
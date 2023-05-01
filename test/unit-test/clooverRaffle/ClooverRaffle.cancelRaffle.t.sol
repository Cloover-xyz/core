// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract CancelClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();
    }

    function test_CancelClooverRaffle() external{
        changePrank(alice);

        tokenClooverRaffle.cancelClooverRaffle();
        assertEq(mockERC20.balanceOf(address(tokenClooverRaffle)), 0);
        assertEq(mockERC721.ownerOf(tokenNftId), alice);

        ethClooverRaffle.cancelClooverRaffle();
        assertEq(address(ethClooverRaffle).balance, 0);
        assertEq(mockERC721.ownerOf(ethNftId), alice);
    }

    function test_CancelClooverRaffle_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);

        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenClooverRaffle.cancelClooverRaffle();

        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethClooverRaffle.cancelClooverRaffle();
    }

    function test_CancelClooverRaffle_RevertWhen_AtLeastOneTicketHasBeenSold() external{
        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffle), 100e18);
        tokenClooverRaffle.purchaseTickets(1);
        changePrank(alice);
        vm.expectRevert(Errors.SALES_ALREADY_STARTED.selector);
        tokenClooverRaffle.cancelClooverRaffle();
        
        changePrank(bob);
        ethClooverRaffle.purchaseTicketsInEth{value: ticketPrice}(1);
        changePrank(alice);
        vm.expectRevert(Errors.SALES_ALREADY_STARTED.selector);
        ethClooverRaffle.cancelClooverRaffle();
    }

    function test_CancelClooverRaffle_RefundInsurancePaid() external{
        changePrank(carole);

        tokenClooverRaffleWithInsurance.cancelClooverRaffle();
        assertEq(mockERC20.balanceOf(address(tokenClooverRaffleWithInsurance)), 0);
        assertEq(mockERC20.balanceOf(carole), 100e18);
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);

        ethClooverRaffleWithInsurance.cancelClooverRaffle();
        assertEq(address(ethClooverRaffleWithInsurance).balance, 0);
        assertEq(carole.balance, 100e18);
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
    }
}
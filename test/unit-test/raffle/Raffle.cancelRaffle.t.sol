// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupRaffles} from "./SetupRaffles.sol";

contract CancelRaffleTest is Test, SetupRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupRaffles.setUp();
    }

    function test_CancelRaffle() external{
        changePrank(alice);

        tokenRaffle.cancelRaffle();
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 0);
        assertEq(mockERC721.ownerOf(tokenNftId), alice);

        ethRaffle.cancelRaffle();
        assertEq(address(ethRaffle).balance, 0);
        assertEq(mockERC721.ownerOf(ethNftId), alice);
    }

    function test_CancelRaffle_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);

        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenRaffle.cancelRaffle();

        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethRaffle.cancelRaffle();
    }

    function test_CancelRaffle_RevertWhen_AtLeastOneTicketHasBeenSold() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e18);
        tokenRaffle.purchaseTickets(1);
        changePrank(alice);
        vm.expectRevert(Errors.SALES_ALREADY_STARTED.selector);
        tokenRaffle.cancelRaffle();
        
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: ticketPrice}(1);
        changePrank(alice);
        vm.expectRevert(Errors.SALES_ALREADY_STARTED.selector);
        ethRaffle.cancelRaffle();
    }

    function test_CancelRaffle_RefundInsurancePaid() external{
        changePrank(carole);

        tokenRaffleWithInsurance.cancelRaffle();
        assertEq(mockERC20.balanceOf(address(tokenRaffleWithInsurance)), 0);
        assertEq(mockERC20.balanceOf(carole), 100e18);
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);

        ethRaffleWithInsurance.cancelRaffle();
        assertEq(address(ethRaffleWithInsurance).balance, 0);
        assertEq(carole.balance, 100e18);
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
    }
}
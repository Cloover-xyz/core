// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";

import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract UserClaimClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();

        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffleWithInsurance), 100e18);
        tokenClooverRaffleWithInsurance.purchaseTickets(2);
        ethClooverRaffleWithInsurance.purchaseTicketsInEth{value: ticketPrice * 2}(2);
    }
 
    function test_UserClaimRefund() external {
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        uint256 bobPrevBalance = mockERC20.balanceOf(bob);
        tokenClooverRaffleWithInsurance.userClaimRefund();

        (,uint256 insurancePartPerTicket) = InsuranceLogic.calculateInsuranceSplit(
            INSURANCE_SALES_PERCENTAGE, 
            PROTOCOL_FEES_PERCENTAGE,
            minTicketSalesInsurance,
            ticketPrice,
            2    
        );
        uint256 expectedBobRefunds = insurancePartPerTicket * 2 + ticketPrice * 2;
        assertEq(mockERC20.balanceOf(bob),bobPrevBalance+ expectedBobRefunds );
    }

    function test_UserClaimRefund_RevertWhen_NotEthClooverRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethClooverRaffleWithInsurance.userClaimRefund();
    }

    function test_UserClaimRefund_RevertWhen_TicketSupplyGreaterThanMinInsuranceSales() external{
        changePrank(bob);
        tokenClooverRaffleWithInsurance.purchaseTickets(5);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        tokenClooverRaffleWithInsurance.userClaimRefund();
    }

    function test_UserClaimRefund_RevertWhen_UserAlreadyClaimedRefund() external {
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffleWithInsurance.userClaimRefund();
        vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
        tokenClooverRaffleWithInsurance.userClaimRefund();
    }

    function test_UserClaimRefund_RevertWhen_CallerDidntPurchaseTicket() external {
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        tokenClooverRaffleWithInsurance.userClaimRefund();
    }

    function test_UserClaimRefundInEth() external {
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        uint256 bobPrevBalance = address(bob).balance;
        ethClooverRaffleWithInsurance.userClaimRefundInEth();

        (,uint256 insurancePartPerTicket) = InsuranceLogic.calculateInsuranceSplit(
            INSURANCE_SALES_PERCENTAGE, 
            PROTOCOL_FEES_PERCENTAGE,
            minTicketSalesInsurance,
            ticketPrice,
            2    
        );
        uint256 expectedBobRefunds = insurancePartPerTicket * 2 + ticketPrice * 2;
        assertEq(address(bob).balance,bobPrevBalance+ expectedBobRefunds);
    }

    function test_UserClaimRefundInEth_RevertWhen_IsEthClooverRaffle() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenClooverRaffle.userClaimRefundInEth();
    }

    function test_UserClaimRefundInEth_RevertWhen_TicketSupplyGreaterThanMinInsuranceSales() external{
        changePrank(bob);
        ethClooverRaffleWithInsurance.purchaseTicketsInEth{value: ticketPrice * 5}(5);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        ethClooverRaffleWithInsurance.userClaimRefundInEth();
    }

    function test_UserClaimRefundInEth_RevertWhen_UserAlreadyClaimedRefund() external {
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffleWithInsurance.userClaimRefundInEth();
        vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
        ethClooverRaffleWithInsurance.userClaimRefundInEth();
    }

    function test_UserClaimRefundInEth_RevertWhen_CallerDidntPurchaseTicket() external {
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        ethClooverRaffleWithInsurance.userClaimRefundInEth();
    }
}
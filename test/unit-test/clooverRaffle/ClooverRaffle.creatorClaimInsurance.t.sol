// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";

import {ClooverRaffle} from "../../../src/raffle/ClooverRaffle.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";

import {ClooverRaffleDataTypes} from "../../../src/libraries/types/ClooverRaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";
import {PercentageMath} from "../../../src/libraries/math/PercentageMath.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract CreatorClaimInsuranceClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;
    using PercentageMath for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();
    }

    function test_CreatorClaimInsurance() external {
        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffleWithInsurance), 100e18);
        tokenClooverRaffleWithInsurance.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        
        changePrank(carole);
        uint256 caroleBalanceBefore = mockERC20.balanceOf(carole);
        tokenClooverRaffleWithInsurance.creatorClaimInsurance();
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);
        uint256 insurancePaid = tokenClooverRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(PROTOCOL_FEES_PERCENTAGE);
        assertEq(mockERC20.balanceOf(treasury),treasuryAmount);
        assertEq(mockERC20.balanceOf(carole),caroleBalanceBefore);
    }

    function test_CreatorClaimInsurance_RevertWhen_IsEthRaffe() external{
        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethClooverRaffleWithInsurance.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_RevertWhen_CreatorDidNotTookInsurance() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NO_INSURANCE_TAKEN.selector);
        tokenClooverRaffle.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_RevertWhen_CreatorAlreadyExerciceRefund() external{
        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffleWithInsurance), 100e18);
        tokenClooverRaffleWithInsurance.purchaseTickets(2);

        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        tokenClooverRaffleWithInsurance.creatorClaimInsurance();
        vm.expectRevert();
        tokenClooverRaffleWithInsurance.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenClooverRaffleWithInsurance.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_RevertWhen_NoTicketHaveBeenSold() external{
        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        tokenClooverRaffleWithInsurance.creatorClaimInsurance();
    }

    function test_CreatorClaimInsurance_RevertWhen_TicketSalesAreEqualOrHigherThanInsurance() external{
        changePrank(bob);
        mockERC20.approve(address(tokenClooverRaffleWithInsurance), 100e18);
        tokenClooverRaffleWithInsurance.purchaseTickets(5);

        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        tokenClooverRaffleWithInsurance.creatorClaimInsurance();
    }

    function test_CreatorClaimInsuranceInEth() external{
        changePrank(bob);
        ethClooverRaffleWithInsurance.purchaseTicketsInEth{value: ticketPrice * 2}(2);
        
        changePrank(carole);
        uint256 caroleBalanceBefore = address(carole).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffleWithInsurance.creatorClaimInsuranceInEth();
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
        uint256 insurancePaid = ethClooverRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(PROTOCOL_FEES_PERCENTAGE);
        assertEq(address(treasury).balance, treasuryAmount + treasuryBalanceBefore);
        assertEq(address(carole).balance, caroleBalanceBefore);
    }

    function test_CreatorClaimInsuranceInEth_RevertWhen_NotEthRaffe() external{
        changePrank(carole);       
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenClooverRaffleWithInsurance.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsuranceInEth_RevertWhen_CreatorAlreadyExerciceRefund() external{
        changePrank(bob);
        ethClooverRaffleWithInsurance.purchaseTicketsInEth{value: ticketPrice * 2}(2);

        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        ethClooverRaffleWithInsurance.creatorClaimInsuranceInEth();
        vm.expectRevert();
        ethClooverRaffleWithInsurance.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsuranceInEth_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethClooverRaffleWithInsurance.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsuranceInEth_RevertWhen_CreatorDidNotTookInsurance() external{
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NO_INSURANCE_TAKEN.selector);
        ethClooverRaffle.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsuranceInEth_RevertWhen_NoTicketHaveBeenSold() external{
        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        ethClooverRaffleWithInsurance.creatorClaimInsuranceInEth();
    }

    function test_CreatorClaimInsuranceInEth_RevertWhen_TicketSalesAreEqualOrHigherThanInsurance() external{
        changePrank(bob);
        ethClooverRaffleWithInsurance.purchaseTicketsInEth{value: ticketPrice * 5}(5);

        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        ethClooverRaffleWithInsurance.creatorClaimInsuranceInEth();
    }

}
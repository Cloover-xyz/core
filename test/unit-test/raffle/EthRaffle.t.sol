// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockRandomProvider} from "../../../src/mocks/MockRandomProvider.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {NFTCollectionWhitelist} from "../../../src/core/NFTCollectionWhitelist.sol";
import {TokenWhitelist} from "../../../src/core/TokenWhitelist.sol";
import {ConfigManager} from "../../../src/core/ConfigManager.sol";

import {Raffle} from "../../../src/raffle/Raffle.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";
import {ConfiguratorInputTypes} from "../../../src/libraries/types/ConfiguratorInputTypes.sol";
import {RaffleDataTypes} from "../../../src/libraries/types/RaffleDataTypes.sol";
import {PercentageMath} from "../../../src/libraries/math/PercentageMath.sol";
import {InsuranceLogic} from "../../../src/libraries/logic/InsuranceLogic.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";


contract EthRaffleTest is Test, SetupUsers {
    using InsuranceLogic for uint;
    using PercentageMath for uint;

    MockERC721 mockERC721;
    MockRandomProvider mockRamdomProvider;

    ConfigManager configManager;
    
    Raffle ethRaffle;
    Raffle ethRaffleWithInsurance;
    ImplementationManager implementationManager;
    NFTCollectionWhitelist nftCollectionWhitelist;
    TokenWhitelist tokenWhitelist;
    AccessController accessController;

    uint256 maxTicketSupply = 10;
    uint256 ethNftId = 1;
    uint256 ethWithAssuranceNftId = 2;

    uint256 ticketPrice = 1e18; // 1
    uint256 minTicketSalesInsurance = 5; // 10
    uint64  ticketSaleDuration = 1 days;

    uint256 MIN_SALE_DURATION = 1 days;
    uint256 MAX_SALE_DURATION = 2 weeks;
    uint256 MAX_TICKET_SUPPLY = 10000;
    uint256 FEE_PERCENTAGE = 1e2; // 1%
    uint256 INSURANCE_SALES_PERCENTAGE = 2.5e2; //2.5%

    function setUp() public virtual override {
        SetupUsers.setUp();

        changePrank(deployer);
        mockERC721 = new MockERC721("Mocked NFT", "NFT");
        mockERC721.mint(alice, ethNftId);
        mockERC721.mint(carole, ethWithAssuranceNftId);

        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));
        nftCollectionWhitelist = new NFTCollectionWhitelist(implementationManager);
        tokenWhitelist = new TokenWhitelist(implementationManager);
        ConfiguratorInputTypes.InitConfigManagerInput memory configData = ConfiguratorInputTypes.InitConfigManagerInput(
                FEE_PERCENTAGE,
                MAX_TICKET_SUPPLY,
                MIN_SALE_DURATION,
                MAX_SALE_DURATION,
                INSURANCE_SALES_PERCENTAGE
                );
        configManager = new ConfigManager(implementationManager, configData);
        mockRamdomProvider = new MockRandomProvider(implementationManager);

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
                ImplementationInterfaceNames.RaffleFactory,
                deployer
        );
        implementationManager.changeImplementationAddress(
                ImplementationInterfaceNames.ConfigManager,
                address(configManager)
        );
        implementationManager.changeImplementationAddress(
                ImplementationInterfaceNames.NFTWhitelist,
                address(nftCollectionWhitelist)
        );
        implementationManager.changeImplementationAddress(
                ImplementationInterfaceNames.TokenWhitelist,
                address(tokenWhitelist)
        );
        implementationManager.changeImplementationAddress(
                ImplementationInterfaceNames.RandomProvider,
                address(mockRamdomProvider)
        );
        implementationManager.changeImplementationAddress(
                ImplementationInterfaceNames.Treasury,
                treasury
        );
        nftCollectionWhitelist.addToWhitelist(address(mockERC721), admin);

        changePrank(alice);

        ethRaffle = new Raffle();
        RaffleDataTypes.InitRaffleParams memory ethData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                IERC20(address(0)),
                mockERC721,
                alice,
                ethNftId,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                true
        );
        mockERC721.transferFrom(alice, address(ethRaffle), ethNftId);
        ethRaffle.initialize(ethData);

        changePrank(carole);
        ethRaffleWithInsurance = new Raffle();
        RaffleDataTypes.InitRaffleParams memory ethRaffleWithInsuranceData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                IERC20(address(0)),
                mockERC721,
                carole,
                ethWithAssuranceNftId,
                maxTicketSupply,
                ticketPrice,
                minTicketSalesInsurance,
                ticketSaleDuration,
                true
        );
        mockERC721.transferFrom(carole, address(ethRaffleWithInsurance), ethWithAssuranceNftId);
         uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        ethRaffleWithInsurance.initialize{value:insuranceCost}(ethRaffleWithInsuranceData);

    }

    function test_raffleCorrecltyInitialize() external{
        // Without insurance
        assertEq(ethRaffle.creator(), alice);
        assertEq(ethRaffle.ticketPrice(), ticketPrice);
        assertEq(ethRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(ethRaffle.totalSupply(), 0);
        assertEq(ethRaffle.maxSupply(), maxTicketSupply);
        assertTrue(ethRaffle.isEthTokenSales());
        assertEq(address(ethRaffle.purchaseCurrency()), address(0));
        (IERC721 contractAddress, uint256 id )= ethRaffle.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,ethNftId);
        assertEq(contractAddress.ownerOf(ethNftId) ,address(ethRaffle));

        // With insurance
        uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        assertEq(ethRaffleWithInsurance.creator(), carole);
        assertEq(ethRaffleWithInsurance.ticketPrice(), ticketPrice);
        assertEq(ethRaffleWithInsurance.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(ethRaffleWithInsurance.totalSupply(), 0);
        assertEq(ethRaffleWithInsurance.maxSupply(), maxTicketSupply);
        assertEq(ethRaffleWithInsurance.insurancePaid(), insuranceCost);
        assertTrue(ethRaffleWithInsurance.isEthTokenSales());
        assertEq(address(ethRaffleWithInsurance.purchaseCurrency()), address(0));
        (contractAddress, id )= ethRaffleWithInsurance.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,ethWithAssuranceNftId);
        assertEq(contractAddress.ownerOf(ethWithAssuranceNftId) ,address(ethRaffleWithInsurance));
    }

    function test_RevertIf_RaffleAlreadyInitialize() external{
        RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            ethNftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            true
        );
        vm.expectRevert("Initializable: contract is already initialized");
        ethRaffle.initialize(data);
    }

    function test_RevertIf_RaffleInitializeDataNotCorrect() external{
        changePrank(alice);
        uint _nftId = 3;
        Raffle newRaffle = new Raffle();
        mockERC721.mint(alice, _nftId);
        mockERC721.transferFrom(alice, address(newRaffle), _nftId);
        //implementationManager == address(0)
        RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
            ImplementationManager(address(0)),
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            true
        );
        vm.expectRevert(Errors.NOT_ADDRESS_0.selector);
        newRaffle.initialize(data);

    
        //NFT not whitelisted
        MockERC721 notWhitelistedCollection = new MockERC721("NOT WHITELISTED", "NFT");
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            notWhitelistedCollection,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            true
        );
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        newRaffle.initialize(data);

        // ticketPrice == 0
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            0,
            0,
            ticketSaleDuration,
            true
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newRaffle.initialize(data);

        // maxTicketSupply == 0
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            0,
            ticketPrice,
            0,
            ticketSaleDuration,
            true
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newRaffle.initialize(data);

        // maxTicketSupply > maxTicketSupplyAllowed
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            MAX_TICKET_SUPPLY+1,
            ticketPrice,
            0,
            ticketSaleDuration,
            true
        );
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        newRaffle.initialize(data);

        // ticketSaleDuration < minTicketSalesDuration
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            uint64(MIN_SALE_DURATION) - 1,
            true
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newRaffle.initialize(data);

        // ticketSaleDuration > maxTicketSalesDuration
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            uint64(MAX_SALE_DURATION) + 1,
            true
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newRaffle.initialize(data);

        // msg.value != insuranceCost
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            minTicketSalesInsurance,
            ticketSaleDuration,
            true
        );
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newRaffle.initialize(data);

    }


    function test_UserCanPurchaseTicket() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);

        assertEq(ethRaffle.ownerOf(0), address(0));
        assertEq(ethRaffle.ownerOf(1), bob);
        assertEq(ethRaffle.ownerOf(2), bob);
        uint256[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 2);
        assertEq(bobTickets[0], 1);
        assertEq(ethRaffle.totalSupply(), 2);
        assertEq(address(ethRaffle).balance, 2e18);
    }

    function test_UserCanPurchaseSeveralTickets() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 1e19}(10);

        assertEq(ethRaffle.ownerOf(0), address(0));
        assertEq(ethRaffle.ownerOf(1), bob);
        assertEq(ethRaffle.ownerOf(10), bob);
        uint256[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(ethRaffle.totalSupply(), 10);
        assertEq(address(ethRaffle).balance, 1e19);
    }

    function test_RevertWhen_UserPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
        ethRaffle.purchaseTicketsInEth{value: 11e18}(11);
    }

    function test_RevertIf_UserSentWrongAmountOfEthForPurchase() external{
        changePrank(alice);
        vm.expectRevert(Errors.WRONG_MSG_VALUE.selector);
        ethRaffle.purchaseTicketsInEth{value: 1e19}(1);
    }

    function test_RevertIf_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        ethRaffle.purchaseTicketsInEth(0);
    }


    function test_RevertIf_UserPurchaseTicketInTokenInsteadOfEth() external{
        changePrank(bob);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.purchaseTickets(1);
    }

    function test_RevertIf_UserPurchaseTicketsAfterTicketSalesEnd() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        ethRaffle.purchaseTicketsInEth{value: 1e18}(1);
    }

    function test_CorrectlyDrawnWinningTickets() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(ethRaffle.winnerAddress() == address(0));
        assertTrue(ethRaffle.winnerAddress() == bob);
    }

    function test_RevertWhen_DrawnATicketCalledOnRaffleNotEnded() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        ethRaffle.drawnTickets();
    }

    function test_StatusBackToInitRandomNumberTicketDrawnedIsZero() external{
        changePrank(bob);
        
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.requestRandomNumberReturnZero(requestId);
        assertTrue(ethRaffle.raffleStatus() == RaffleDataTypes.RaffleStatus.Init);
    }

    function test_RevertWhen_DrawnATicketCalledButAlreadyDrawn() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
        ethRaffle.drawnTickets();
    }

    function test_UserCanClaimHisPrice() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 winningTicketNumber = 1;
        vm.store(address(ethRaffle),bytes32(uint256(12)), bytes32(winningTicketNumber));
        assertEq(ethRaffle.winningTicket(), winningTicketNumber);
        ethRaffle.winnerClaimPrice();
        assertEq(mockERC721.ownerOf(ethNftId),bob);
        assertEq(ethRaffle.winnerAddress(), bob);
    }

    function test_RevertIf_UserCallClaimPriceWhenRaffleStillOpen() external{
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        ethRaffle.winnerClaimPrice();
    }

    function test_RevertWhen_NotWinnerTryToCallWinnerClaimPrice() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 10e18}(10);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        ethRaffle.winnerClaimPrice();
    }

    function test_RevertWhen_UserClaimPriceButDrawnHasNotBeDone() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        ethRaffle.winnerClaimPrice();
    }

    function test_CorrectlyClaimTicketSalesAmount() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        uint256 aliceBalanceBefore = address(alice).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        uint256 totalSalesAmount = 2e18;
        ethRaffle.claimEthTicketSalesAmount();
        assertEq(address(treasury).balance, treasuryBalanceBefore + totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(address(alice).balance, aliceBalanceBefore + totalSalesAmount - totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(address(ethRaffle).balance, 0);
    }

    function test_RevertIf_CreatorClaimTokenTicketSalesAmountInsteadOfEth() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.claimTokenTicketSalesAmount();
    }

    function test_RevertIf_NotCreatorClaimEthTicketSalesAmount() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethRaffle.claimEthTicketSalesAmount();
    }

    function test_RevertIf_WinningTicketNotDrawnBeforeClaimingEthTicketSalesAmount() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        changePrank(alice);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        ethRaffle.claimEthTicketSalesAmount();
    }


    function test_CreatorCanCallInsuranceAndGetPartOfInsuranceIfNotTicketHasBeenSold() external{
        changePrank(carole);
        uint256 caroleBalanceBefore = address(carole).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffleWithInsurance.creatorExerciseEthInsurance();
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
        uint256 insurancePaid = ethRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(address(treasury).balance, treasuryAmount + treasuryBalanceBefore);
        uint256 expectedCaroleBalance = caroleBalanceBefore + insurancePaid - treasuryAmount;
        assertEq(address(carole).balance, expectedCaroleBalance);
    }

    function test_CreatorCanCallInsuranceAfterDrawnTicketCall() external{
        changePrank(carole);
        uint256 caroleBalanceBefore = address(carole).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffleWithInsurance.drawnTickets();
        ethRaffleWithInsurance.creatorExerciseEthInsurance();
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
        uint256 insurancePaid = ethRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(address(treasury).balance, treasuryAmount + treasuryBalanceBefore);
        uint256 expectedCaroleBalance = caroleBalanceBefore + insurancePaid - treasuryAmount;
        assertEq(address(carole).balance, expectedCaroleBalance);
    }


    function test_CreatorCanCallInsuranceAndDontGetPartOfInsuranceIfTicketHasBeenSold() external{
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 2e18}(2);
        changePrank(carole);
        uint256 caroleBalanceBefore = address(carole).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
         ethRaffleWithInsurance.creatorExerciseEthInsurance();
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
        uint256 insurancePaid = ethRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(address(treasury).balance, treasuryAmount + treasuryBalanceBefore);
        assertEq(address(carole).balance, caroleBalanceBefore);
    }

    function test_RevertIf_CreatorCallExerciceTokenInsuranceWhenItsEthRaffe() external{
        changePrank(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffleWithInsurance.creatorExerciseTokenInsurance();
    }

    function test_RevertIf_CreatorAlreadyExerciceInsurance() external{
        changePrank(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffleWithInsurance.creatorExerciseEthInsurance();
        vm.expectRevert();
        ethRaffleWithInsurance.creatorExerciseEthInsurance();
    }
    function test_RevertIf_NotCreatorCallExerciseInsurance() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethRaffleWithInsurance.creatorExerciseEthInsurance();
    }

    function test_RevertIf_CreatorExerciseEthInsuranceWhereTicketSalesAreEqualOrHigherThanInsurance() external{
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 5e18}(5);

        changePrank(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        ethRaffleWithInsurance.creatorExerciseEthInsurance();
    }

    function test_UserCanGetRefundsWithInsurancePart() external {
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        uint256 bobPrevBalance = address(bob).balance;
        ethRaffleWithInsurance.userExerciseEthInsuranceRefund();

        (,uint256 insurancePartPerTicket) = InsuranceLogic.calculateInsuranceSplit(
            INSURANCE_SALES_PERCENTAGE, 
            FEE_PERCENTAGE,
            minTicketSalesInsurance,
            ticketPrice,
            2    
        );
        uint256 expectedBobRefunds = insurancePartPerTicket * 2 + ticketPrice * 2;
        assertEq(address(bob).balance,bobPrevBalance+ expectedBobRefunds);
    }

    function test_RevertWhen_UserClaimTokenInsuranceRefundOnAnEthRaffle() external{
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffleWithInsurance.userExerciseTokenInsuranceRefund();
    }

    function test_RevertWhen_UserClaimEthInsuranceRefundOnTicketSupplyGreaterThanMinInsuranceSales() external{
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 5e18}(5);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        ethRaffleWithInsurance.userExerciseEthInsuranceRefund();
    }

    function test_RevertWhen_UserAlreadyClaimRefundsWithInsurancePart() external {
        changePrank(bob);
       ethRaffleWithInsurance.purchaseTicketsInEth{value: 2e18}(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        ethRaffleWithInsurance.userExerciseEthInsuranceRefund();
        vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
        ethRaffleWithInsurance.userExerciseEthInsuranceRefund();
    }

    function test_RevertWhen_UserDidntPurchaseTicketAndClaimRefund() external {
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        ethRaffleWithInsurance.userExerciseEthInsuranceRefund();
    }
}   
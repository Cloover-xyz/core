// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockRandomProvider} from "../../../src/mocks/MockRandomProvider.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";
import {MockERC20} from "../../../src/mocks/MockERC20.sol";

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
    MockERC20 mockERC20;
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

        vm.startPrank(deployer);
        mockERC721 = new MockERC721("Mocked NFT", "NFT");
        mockERC721.mint(alice, ethNftId);
        mockERC721.mint(carole, ethWithAssuranceNftId);
        mockERC20 = new MockERC20("MockERC20", "M20", 18);
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
        tokenWhitelist.addToWhitelist(address(mockERC20));

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
                true,
                0
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
                true,
                0
        );
        mockERC721.transferFrom(carole, address(ethRaffleWithInsurance), ethWithAssuranceNftId);
         uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        ethRaffleWithInsurance.initialize{value:insuranceCost}(ethRaffleWithInsuranceData);

    }

    function test_Initialize_EthRaffle() external{
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

    function test_Initialize_RevertWhen_RaffleAlreadyInitialize() external{
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
            true,
                0
        );
        vm.expectRevert("Initializable: contract is already initialized");
        ethRaffle.initialize(data);
    }

    function test_Initialize_RevertWhen_RaffleDataNotCorrect() external{
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
            true,
                0
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
            true,
            0
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
            true,
            0
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
            true,
            0
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
            true,
            0
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
            true,
            0
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
            true,
            0
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
            true,
            0
        );
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newRaffle.initialize(data);
    }

    function test_PurchaseTicketsInEth() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 1e18}(1);

        assertEq(ethRaffle.ownerOf(0), address(0));
        assertEq(ethRaffle.ownerOf(1), bob);
        uint256[] memory bobTickets = ethRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 1);
        assertEq(bobTickets[0], 1);
        assertEq(ethRaffle.totalSupply(), 1);
        assertEq(address(ethRaffle).balance, 1e18);
    }

    function test_PurchaseTicketsInEth_SeveralTimes() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 1e18}(1);
        ethRaffle.purchaseTicketsInEth{value: 9e18}(9);

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

    function test_PurchaseTicketsInEth_SeveralTickets() external{
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

    function test_PurchaseTicketsInEth_RevertWhen_NewPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
        ethRaffle.purchaseTicketsInEth{value: 11e18}(11);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserSendWrongAmountOfEthForPurchase() external{
        changePrank(alice);
        vm.expectRevert(Errors.WRONG_MSG_VALUE.selector);
        ethRaffle.purchaseTicketsInEth{value: 1e19}(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        ethRaffle.purchaseTicketsInEth(0);
    }

    function test_PurchaseTicketsInEth_RevertWhen_NotEthRaffle() external{
        changePrank(alice);
        Raffle tokenRaffle = new Raffle();
        mockERC721.mint(alice, 3);
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                mockERC20,
                mockERC721,
                alice,
                3,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                false,
                0
        );
        mockERC721.transferFrom(alice, address(tokenRaffle), 3);
        tokenRaffle.initialize(raffleData);
        
        changePrank(bob);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.purchaseTicketsInEth(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_TicketSalesClose() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        ethRaffle.purchaseTicketsInEth{value: 1e18}(1);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserTicketPurchaseExceedLimitAllowed() external{
        changePrank(alice);
        mockERC721.mint(alice, 3);
        Raffle ethRaffleLimit = new Raffle();
        RaffleDataTypes.InitRaffleParams memory ethData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                IERC20(address(0)),
                mockERC721,
                alice,
                3,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                true,
                5
        );
        mockERC721.transferFrom(alice, address(ethRaffleLimit), 3);
        ethRaffleLimit.initialize(ethData);

        changePrank(bob);
        ethRaffleLimit.purchaseTicketsInEth{value: 4e18}(4);
        vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
        ethRaffleLimit.purchaseTicketsInEth{value: 5e18}(5);
    }

    function test_DrawnTickets() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(ethRaffle.winnerAddress() == address(0));
        assertTrue(ethRaffle.winnerAddress() == bob);
    }

    function test_DrawnTickets_RevertWhen_TicketSalesStillOpen() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        ethRaffle.drawnTickets();
    }

    function test_DrawnTickets_StatusBackToInitWhenRandomNumberTicketDrawnedIsZero() external{
        changePrank(bob);
        
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.requestRandomNumberReturnZero(requestId);
        assertTrue(ethRaffle.raffleStatus() == RaffleDataTypes.RaffleStatus.Init);
    }

    function test_DrawnTickets_RevertWhen_TicketAlreadyDrawn() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
        ethRaffle.drawnTickets();
    }

    function test_WinnerClaimPrice() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
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

    function test_WinnerClaimPrice_RevertWhen_RaffleStillOpen() external{
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        ethRaffle.winnerClaimPrice();
    }

    function test_WinnerClaimPrice_RevertWhen_NotWinnerTryToClaimPrice() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 10e18}(10);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        ethRaffle.winnerClaimPrice();
    }

    function test_WinnerClaimPrice_RevertWhen_DrawnHasNotBeDone() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        ethRaffle.winnerClaimPrice();
    }

    function test_ClaimEthTicketSalesAmount() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
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

    function test_ClaimEthTicketSalesAmount_RevertWhen_NotEthRaffle() external{
        changePrank(alice);
        Raffle tokenRaffle = new Raffle();
        mockERC721.mint(alice, 3);
        mockERC20.mint(bob, 100e18);
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                mockERC20,
                mockERC721,
                alice,
                3,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                false,
                0
        );
        mockERC721.transferFrom(alice, address(tokenRaffle), 3);
        tokenRaffle.initialize(raffleData);
        
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e18);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.claimEthTicketSalesAmount();
    }

    function test_ClaimEthTicketSalesAmount_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethRaffle.claimEthTicketSalesAmount();
    }

    function test_ClaimEthTicketSalesAmount_RevertWhen_WinningTicketNotDrawn() external{
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
        changePrank(alice);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        ethRaffle.claimEthTicketSalesAmount();
    }

    function test_CreatorExerciseRefundInEth_GetBackHisNFTWhenNoInsuranceWasPaidAndNoTicketSold() external {
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.creatorExerciseRefundInEth();
        assertEq(mockERC721.ownerOf(ethNftId), alice);
    }

    function test_CreatorExerciseRefundInEth_GetBackPartOfInsuranceIfNoTicketHasBeenSold() external{
        changePrank(carole);
        uint256 caroleBalanceBefore = address(carole).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        utils.goForward(ticketSaleDuration + 1);
        ethRaffleWithInsurance.creatorExerciseRefundInEth();
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
        uint256 insurancePaid = ethRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(address(treasury).balance, treasuryAmount + treasuryBalanceBefore);
        uint256 expectedCaroleBalance = caroleBalanceBefore + insurancePaid - treasuryAmount;
        assertEq(address(carole).balance, expectedCaroleBalance);
    }

    function test_CreatorExerciseRefundInEth_CanBeCallAfterDrawnTicketCallSetStatusToRefundMode() external{
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 2e18}(2);
        changePrank(carole);
        uint256 caroleBalanceBefore = address(carole).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        utils.goForward(ticketSaleDuration + 1);
        ethRaffleWithInsurance.drawnTickets();
        ethRaffleWithInsurance.creatorExerciseRefundInEth();
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
        uint256 insurancePaid = ethRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(address(treasury).balance, treasuryAmount + treasuryBalanceBefore);
        assertEq(address(carole).balance, caroleBalanceBefore);
    }

    function test_CreatorExerciseRefundInEth_DontGetBackInsurancePaidIfTicketHasBeenSold() external{
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 2e18}(2);
        changePrank(carole);
        uint256 caroleBalanceBefore = address(carole).balance;
        uint256 treasuryBalanceBefore = address(treasury).balance;
        utils.goForward(ticketSaleDuration + 1);
        ethRaffleWithInsurance.creatorExerciseRefundInEth();
        assertEq(mockERC721.ownerOf(ethWithAssuranceNftId), carole);
        uint256 insurancePaid = ethRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(address(treasury).balance, treasuryAmount + treasuryBalanceBefore);
        assertEq(address(carole).balance, caroleBalanceBefore);
    }

    function test_CreatorExerciseRefundInEth_RevertWhen_NotEthRaffe() external{
        changePrank(alice);
        Raffle tokenRaffle = new Raffle();
        mockERC721.mint(alice, 3);
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                mockERC20,
                mockERC721,
                alice,
                3,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                false,
                0
        );
        mockERC721.transferFrom(alice, address(tokenRaffle), 3);
        tokenRaffle.initialize(raffleData);
        
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.creatorExerciseRefundInEth();
    }

    function test_CreatorExerciseRefundInEth_RevertWhen_CreatorAlreadyExerciceRefund() external{
        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffleWithInsurance.creatorExerciseRefundInEth();
        vm.expectRevert();
        ethRaffleWithInsurance.creatorExerciseRefundInEth();
    }

    function test_CreatorExerciseRefundInEth_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        ethRaffleWithInsurance.creatorExerciseRefundInEth();
    }

    function test_CreatorExerciseRefundInEth_RevertWhen_TicketSalesAreEqualOrHigherThanInsurance() external{
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 5e18}(5);

        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        ethRaffleWithInsurance.creatorExerciseRefundInEth();
    }

    function test_UserExerciseRefundInEth() external {
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
        uint256 bobPrevBalance = address(bob).balance;
        ethRaffleWithInsurance.userExerciseRefundInEth();

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

    function test_UserExerciseRefundInEth_RevertWhen_NotEthRaffle() external{
        changePrank(alice);
        Raffle tokenRaffle = new Raffle();
        mockERC721.mint(alice, 3);
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                mockERC20,
                mockERC721,
                alice,
                3,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                false,
                0
        );
        mockERC721.transferFrom(alice, address(tokenRaffle), 3);
        tokenRaffle.initialize(raffleData);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.userExerciseRefundInEth();
    }

    function test_UserExerciseRefundInEth_RevertWhen_TicketSupplyGreaterThanMinInsuranceSales() external{
        changePrank(bob);
        ethRaffleWithInsurance.purchaseTicketsInEth{value: 5e18}(5);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        ethRaffleWithInsurance.userExerciseRefundInEth();
    }

    function test_UserExerciseRefundInEth_RevertWhen_UserAlreadyClaimedRefund() external {
        changePrank(bob);
       ethRaffleWithInsurance.purchaseTicketsInEth{value: 2e18}(2);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffleWithInsurance.userExerciseRefundInEth();
        vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
        ethRaffleWithInsurance.userExerciseRefundInEth();
    }

    function test_UserExerciseRefundInEth_RevertWhen_CallerDidntPurchaseTicket() external {
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        ethRaffleWithInsurance.userExerciseRefundInEth();
    }
}   
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

import {RaffleFactory} from "../../../src/raffle/RaffleFactory.sol";
import {Raffle} from "../../../src/raffle/Raffle.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";
import {ConfiguratorInputTypes} from "../../../src/libraries/types/ConfiguratorInputTypes.sol";
import {RaffleDataTypes} from "../../../src/libraries/types/RaffleDataTypes.sol";
import {PercentageMath} from "../../../src/libraries/math/PercentageMath.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

contract TokenRaffleTest is Test, SetupUsers {
    using InsuranceLogic for uint;
    using PercentageMath for uint;

    MockERC20  mockERC20;
    MockERC721 mockERC721;
    MockRandomProvider mockRamdomProvider;

    ConfigManager configManager;
    RaffleFactory raffleFactory;
    Raffle tokenRaffle;
    Raffle tokenRaffleWithInsurance;
    ImplementationManager implementationManager;
    NFTCollectionWhitelist nftCollectionWhitelist;
    TokenWhitelist tokenWhitelist;
    AccessController accessController;

    uint256 maxTicketSupply = 10;
    uint256 tokenNftId = 1;
    uint256 tokenWithAssuranceNftId = 2;
    uint256 ticketPrice = 1e7; // 10
    uint256 minTicketSalesInsurance = 5;
    uint64 ticketSaleDuration = 1 days;

    uint256 MIN_SALE_DURATION = 1 days;
    uint256 MAX_SALE_DURATION = 2 weeks;
    uint256 MAX_TICKET_SUPPLY = 10000;
    uint256 FEE_PERCENTAGE = 1e2; // 1%
    uint256 INSURANCE_SALES_PERCENTAGE = 2.5e2; //2.5%

    function setUp() public virtual override {
        SetupUsers.setUp();

        vm.startPrank(deployer);
        mockERC20 = new MockERC20("Mocked USDC", "USDC", 6);
        mockERC20.mint(bob, 100e7);
        mockERC20.mint(carole, 100e7);
        mockERC721 = new MockERC721("Mocked NFT", "NFT");
        mockERC721.mint(alice, tokenNftId);
        mockERC721.mint(carole, tokenWithAssuranceNftId);

        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));
        raffleFactory = new RaffleFactory(implementationManager);
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
            address(raffleFactory)
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
        tokenRaffle = new Raffle();
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                mockERC20,
                mockERC721,
                alice,
                tokenNftId,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                false,
                0
        );
        mockERC721.transferFrom(alice, address(tokenRaffle), tokenNftId);
        tokenRaffle.initialize(raffleData);

        changePrank(carole);
        tokenRaffleWithInsurance = new Raffle();
        RaffleDataTypes.InitRaffleParams memory tokenRaffleWithInsuranceData = RaffleDataTypes.InitRaffleParams(
                implementationManager,
                mockERC20,
                mockERC721,
                carole,
                tokenWithAssuranceNftId,
                maxTicketSupply,
                ticketPrice,
                minTicketSalesInsurance,
                ticketSaleDuration,
                false,
                0
        );
        mockERC721.transferFrom(carole, address(tokenRaffleWithInsurance), tokenWithAssuranceNftId);
        uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        mockERC20.transfer(address(tokenRaffleWithInsurance), insuranceCost);
        tokenRaffleWithInsurance.initialize(tokenRaffleWithInsuranceData);
    }

    function test_Initialize_TokenRaffle() external{
        // Without insurance
        assertEq(tokenRaffle.creator(), alice);
        assertEq(tokenRaffle.ticketPrice(), ticketPrice);
        assertEq(tokenRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(tokenRaffle.totalSupply(), 0);
        assertEq(tokenRaffle.maxSupply(), maxTicketSupply);
        assertFalse(tokenRaffle.isEthTokenSales());
        assertEq(address(tokenRaffle.purchaseCurrency()), address(mockERC20));
        (IERC721 contractAddress, uint256 id )= tokenRaffle.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,tokenNftId);
        assertEq(contractAddress.ownerOf(tokenNftId) ,address(tokenRaffle));

        // With insurance
        uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        assertEq(tokenRaffleWithInsurance.creator(), carole);
        assertEq(tokenRaffleWithInsurance.ticketPrice(), ticketPrice);
        assertEq(tokenRaffleWithInsurance.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(tokenRaffleWithInsurance.totalSupply(), 0);
        assertEq(tokenRaffleWithInsurance.maxSupply(), maxTicketSupply);
        assertEq(tokenRaffleWithInsurance.insurancePaid(), insuranceCost);
        assertFalse(tokenRaffleWithInsurance.isEthTokenSales());
        assertEq(address(tokenRaffleWithInsurance.purchaseCurrency()), address(mockERC20));
        (contractAddress, id )= tokenRaffleWithInsurance.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,tokenWithAssuranceNftId);
        assertEq(contractAddress.ownerOf(tokenWithAssuranceNftId) ,address(tokenRaffleWithInsurance));
    }

    function test_Initialize_RevertWhen_RaffleAlreadyInitialize() external{
        RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            tokenNftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            false,
                0
        );
        vm.expectRevert("Initializable: contract is already initialized");
        tokenRaffle.initialize(data);
    }

    function test_Initialize_RevertWhen_RaffleDataNotCorrect() external{
        changePrank(alice);
        uint _nftId = 5;
        Raffle newRaffle = new Raffle();
        mockERC721.mint(alice, _nftId);
        mockERC721.transferFrom(alice, address(newRaffle), _nftId);
        //implementationManager == address(0)
        RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
            ImplementationManager(address(0)),
            mockERC20,
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            false,
                0
        );
        vm.expectRevert(Errors.NOT_ADDRESS_0.selector);
        newRaffle.initialize(data);

        //Token not whitelisted
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            MockERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            false,
                0
        );
        vm.expectRevert(Errors.TOKEN_NOT_WHITELISTED.selector);
        newRaffle.initialize(data);

        //NFT not whitelisted
        MockERC721 notWhitelistedCollection = new MockERC721("NOT WHITELISTED", "NFT");
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            notWhitelistedCollection,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            false,
                0
        );
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        newRaffle.initialize(data);

        // ticketPrice == 0
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            0,
            0,
            ticketSaleDuration,
            false,
                0
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newRaffle.initialize(data);

        // maxTicketSupply == 0
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            _nftId,
            0,
            ticketPrice,
            0,
            ticketSaleDuration,
            false,
                0
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newRaffle.initialize(data);

        // maxTicketSupply > maxTicketSupplyAllowed
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            _nftId,
            MAX_TICKET_SUPPLY+1,
            ticketPrice,
            0,
            ticketSaleDuration,
            false,
                0
        );
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        newRaffle.initialize(data);

        // ticketSaleDuration < minTicketSalesDuration
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            uint64(MIN_SALE_DURATION) - 1,
            false,
                0
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newRaffle.initialize(data);

        // ticketSaleDuration > maxTicketSalesDuration
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            uint64(MAX_SALE_DURATION) + 1,
            false,
                0
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newRaffle.initialize(data);

        //minTicketSalesInsurance > 0 && transfer value == insuranceCost
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            mockERC20,
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            1,
            ticketSaleDuration,
            false,
                0
        );
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newRaffle.initialize(data);
    }

    function test_CancelRaffle() external{
        changePrank(alice);
        tokenRaffle.cancelRaffle();
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 0);
        assertEq(mockERC721.ownerOf(tokenNftId), alice);
    }

    function test_CancelRaffle_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenRaffle.cancelRaffle();
    }

    function test_CancelRaffle_RevertWhen_AtLeastOneTicketHasBeenSold() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(1);

        changePrank(alice);
        vm.expectRevert(Errors.SALES_ALREADY_STARTED.selector);
        tokenRaffle.cancelRaffle();
    }

    function test_CancelRaffle_RefundInsurancePaid() external{
        changePrank(carole);
        tokenRaffleWithInsurance.cancelRaffle();
        assertEq(mockERC20.balanceOf(address(tokenRaffleWithInsurance)), 0);
        assertEq(mockERC20.balanceOf(carole), 100e7);
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);
    }

    function test_PurchaseTickets() external{
        changePrank(bob);

        mockERC20.approve(address(tokenRaffle), 100e6);

        tokenRaffle.purchaseTickets(1);

        assertEq(tokenRaffle.ownerOf(0), address(0));
        assertEq(tokenRaffle.ownerOf(1), bob);
        uint256[] memory bobTickets = tokenRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 1);
        assertEq(bobTickets[0], 1);
        assertEq(tokenRaffle.totalSupply(), 1);
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 1e7);
    }

    function test_PurchaseTickets_SeveralTimes() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(1);
        tokenRaffle.purchaseTickets(9);

        assertEq(tokenRaffle.ownerOf(0), address(0));
        assertEq(tokenRaffle.ownerOf(1), bob);
        assertEq(tokenRaffle.ownerOf(10), bob);
        uint256[] memory bobTickets = tokenRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(tokenRaffle.totalSupply(), 10);
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 100e6);
    }

    function test_PurchaseTickets_RevertWhen_NewPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
        tokenRaffle.purchaseTickets(11);
    }

    function test_PurchaseTicketsInEth_RevertWhen_UserNotHaveEnoughBalance() external{
        changePrank(alice);
        vm.expectRevert("ERC20: insufficient allowance");
        tokenRaffle.purchaseTickets(1);
    }

    function test_PurchaseTickets_RevertWhen_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        tokenRaffle.purchaseTickets(0);
    }

    function test_PurchaseTickets_RevertWhen_UserTicketPurchaseExceedLimitAllowed() external{
        changePrank(alice);
        mockERC721.mint(alice, 3);
        Raffle raffleLimit = new Raffle();
        RaffleDataTypes.InitRaffleParams memory ethData = RaffleDataTypes.InitRaffleParams(
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
                5
        );
        mockERC721.transferFrom(alice, address(raffleLimit), 3);
        raffleLimit.initialize(ethData);

        changePrank(bob);
        mockERC20.approve(address(raffleLimit), 100e6);
        raffleLimit.purchaseTickets(4);
        vm.expectRevert(Errors.EXCEED_MAX_TICKET_ALLOWED_TO_PURCHASE.selector);
        raffleLimit.purchaseTickets(5);
    }

    function test_PurchaseTickets_RevertWhen_IsEthRaffle() external{
        changePrank(alice);
        Raffle ethRaffle = new Raffle();
        mockERC721.mint(alice, 3);
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
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
                0
        );
        mockERC721.transferFrom(alice, address(ethRaffle), 3);
        ethRaffle.initialize(raffleData);
        
        changePrank(bob);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.purchaseTickets(1);
    }

    function test_PurchaseTickets_RevertWhen_TicketSalesClose() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        tokenRaffle.purchaseTickets(1);
    }

    function test_DrawnTickets() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(tokenRaffle.winnerAddress() == address(0));
        assertTrue(tokenRaffle.winnerAddress() == bob);
    }

    function test_DrawnTickets_RevertWhen_TicketSalesStillOpen() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        tokenRaffle.drawnTickets();
    }

    function test_DrawnTickets_StatusBackToInitWhenRandomNumberTicketDrawnedIsZero() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.requestRandomNumberReturnZero(requestId);
        assertTrue(tokenRaffle.raffleStatus() == RaffleDataTypes.RaffleStatus.Init);
    }

    function test_DrawnTickets_RevertWhen_TicketAlreadyDrawn() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
        tokenRaffle.drawnTickets();
    }

    function test_WinnerClaimPrice() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        uint256 winningTicketNumber = 1;
        vm.store(address(tokenRaffle),bytes32(uint256(12)), bytes32(winningTicketNumber));
        assertEq(tokenRaffle.winningTicket(), winningTicketNumber);
        tokenRaffle.winnerClaimPrice();
        assertEq(mockERC721.ownerOf(tokenNftId),bob);
        assertEq(tokenRaffle.winnerAddress(), bob);
    }

    function test_WinnerClaimPrice_RevertWhen_RaffleStillOpen() external{
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        tokenRaffle.winnerClaimPrice();
    }

    function test_WinnerClaimPrice_RevertWhen_NotWinnerTryToClaimPrice() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(10);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        tokenRaffle.winnerClaimPrice();
    }

    function test_WinnerClaimPrice_RevertWhen_DrawnHasNotBeDone() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        tokenRaffle.winnerClaimPrice();
    }

    function test_ClaimTicketSalesAmount() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        uint256 aliceBalanceBefore = mockERC20.balanceOf(alice);
        uint256 treasuryBalanceBefore = mockERC20.balanceOf(treasury);
        uint256 totalSalesAmount = 2e7;
        tokenRaffle.claimTicketSalesAmount();
        assertEq(mockERC20.balanceOf(treasury), treasuryBalanceBefore + totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(mockERC20.balanceOf(alice), aliceBalanceBefore + totalSalesAmount - totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 0);
    }

    function test_ClaimTicketSalesAmount_RevertWhen_IsEthRaffle() external{
        changePrank(alice);
        Raffle ethRaffle = new Raffle();
        mockERC721.mint(alice, 3);
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
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
                0
        );
        mockERC721.transferFrom(alice, address(ethRaffle), 3);
        ethRaffle.initialize(raffleData);
        
        changePrank(bob);
        ethRaffle.purchaseTicketsInEth{value: 2e7}(2);
        utils.goForward(ticketSaleDuration + 1);
        ethRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.claimTicketSalesAmount();
    }

    function test_ClaimTicketSalesAmount_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenRaffle.claimTicketSalesAmount();
    }

    function test_ClaimTicketSalesAmount_RevertWhen_WinningTicketNotDrawn() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        changePrank(alice);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        tokenRaffle.claimTicketSalesAmount();
    }


    function test_CreatorExerciseRefund_GetBackHisNFTWhenNoInsuranceWasPaidAndNoTicketSold() external {
        changePrank(alice);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffle.creatorExerciseRefund();
        assertEq(mockERC721.ownerOf(tokenNftId), alice);
    }


    function test_CreatorExerciseRefund_GetBackPartOfInsuranceIfNoTicketHasBeenSold() external{
        changePrank(carole);
        uint256 caroleBalanceBefore = mockERC20.balanceOf(carole);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffleWithInsurance.creatorExerciseRefund();
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);
        uint256 insurancePaid = tokenRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(mockERC20.balanceOf(treasury),treasuryAmount);
        uint256 expectedCaroleBalance = caroleBalanceBefore + insurancePaid - treasuryAmount;
        assertEq(mockERC20.balanceOf(carole),expectedCaroleBalance);
    }

    function test_CreatorExerciseRefund_CanBeCallAfterDrawnTicketCallSetStatusToRefundMode() external{
        changePrank(carole);
        uint256 caroleBalanceBefore = mockERC20.balanceOf(carole);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffleWithInsurance.drawnTickets();
        tokenRaffleWithInsurance.creatorExerciseRefund();
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);
        uint256 insurancePaid = tokenRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(mockERC20.balanceOf(treasury),treasuryAmount);
        uint256 expectedCaroleBalance = caroleBalanceBefore + insurancePaid - treasuryAmount;
        assertEq(mockERC20.balanceOf(carole),expectedCaroleBalance);
    }

    function test_CreatorExerciseRefund_DontGetBackInsurancePaidIfTicketHasBeenSold() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(2);
        changePrank(carole);
        uint256 caroleBalanceBefore = mockERC20.balanceOf(carole);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffleWithInsurance.creatorExerciseRefund();
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);
        uint256 insurancePaid = tokenRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(mockERC20.balanceOf(treasury),treasuryAmount);
        assertEq(mockERC20.balanceOf(carole),caroleBalanceBefore);
    }

    function test_CreatorExerciseRefund_RevertWhen_IsEthRaffe() external{
        changePrank(alice);
        Raffle ethRaffle = new Raffle();
        mockERC721.mint(alice, 3);
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
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
                0
        );
        mockERC721.transferFrom(alice, address(ethRaffle), 3);
        ethRaffle.initialize(raffleData);

        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.creatorExerciseRefund();
    }

    function test_CreatorExerciseRefund_RevertWhen_CreatorAlreadyExerciceRefund() external{
        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffleWithInsurance.creatorExerciseRefund();
        vm.expectRevert();
        tokenRaffleWithInsurance.creatorExerciseRefund();
    }

    function test_CreatorExerciseRefund_RevertWhen_NotCreatorCalling() external{
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenRaffleWithInsurance.creatorExerciseRefund();
    }

    function test_CreatorExerciseRefund_RevertWhen_TicketSalesAreEqualOrHigherThanInsurance() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(5);

        changePrank(carole);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        tokenRaffleWithInsurance.creatorExerciseRefund();
    }
    
    function test_UserExerciseRefund() external {
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        uint256 bobPrevBalance = mockERC20.balanceOf(bob);
        tokenRaffleWithInsurance.userExerciseRefund();

        (,uint256 insurancePartPerTicket) = InsuranceLogic.calculateInsuranceSplit(
            INSURANCE_SALES_PERCENTAGE, 
            FEE_PERCENTAGE,
            minTicketSalesInsurance,
            ticketPrice,
            2    
        );
        uint256 expectedBobRefunds = insurancePartPerTicket * 2 + ticketPrice * 2;
        assertEq(mockERC20.balanceOf(bob),bobPrevBalance+ expectedBobRefunds );
    }

    function test_UserExerciseRefundInEth_RevertWhen_NotEthRaffle() external{
        changePrank(alice);
        Raffle ethRaffle = new Raffle();
        mockERC721.mint(alice, 3);
        RaffleDataTypes.InitRaffleParams memory raffleData = RaffleDataTypes.InitRaffleParams(
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
                0
        );
                mockERC721.transferFrom(alice, address(ethRaffle), 3);
        ethRaffle.initialize(raffleData);
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
    
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.userExerciseRefund();
    }

    function test_UserExerciseRefundInEth_RevertWhen_TicketSupplyGreaterThanMinInsuranceSales() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(5);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        tokenRaffleWithInsurance.userExerciseRefund();
    }

    function test_UserExerciseRefundInEth_RevertWhen_UserAlreadyClaimedRefund() external {
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(2);
        utils.goForward(ticketSaleDuration + 1);
        tokenRaffleWithInsurance.userExerciseRefund();
        vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
        tokenRaffleWithInsurance.userExerciseRefund();
    }

    function test_UserExerciseRefundInEth_RevertWhen_CallerDidntPurchaseTicket() external {
        changePrank(bob);
        utils.goForward(ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        tokenRaffleWithInsurance.userExerciseRefund();
    }
}
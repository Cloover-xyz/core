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

contract TokenRaffleTest is Test, SetupUsers {
    using InsuranceLogic for uint;
    using PercentageMath for uint;

    MockERC20  mockERC20;
    MockERC721 mockERC721;
    MockRandomProvider mockRamdomProvider;

    ConfigManager configManager;
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

        changePrank(deployer);
        mockERC20 = new MockERC20("Mocked USDC", "USDC", 6);
        mockERC20.mint(bob, 100e7);
        mockERC20.mint(carole, 100e7);
        mockERC721 = new MockERC721("Mocked NFT", "NFT");
        mockERC721.mint(alice, tokenNftId);
        mockERC721.mint(carole, tokenWithAssuranceNftId);

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
                false
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
                false
        );
        mockERC721.transferFrom(carole, address(tokenRaffleWithInsurance), tokenWithAssuranceNftId);
        uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        mockERC20.transfer(address(tokenRaffleWithInsurance), insuranceCost);
        tokenRaffleWithInsurance.initialize(tokenRaffleWithInsuranceData);
    }

    function test_TokenRaffleCorrecltyInitialize() external{
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


    function test_RevertIf_RaffleAlreadyInitialize() external{
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
            false
        );
        vm.expectRevert("Initializable: contract is already initialized");
        tokenRaffle.initialize(data);
    }

    function test_RevertIf_RaffleInitializeDataNotCorrect() external{
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
            false
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
            false
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
            false
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
            false
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
            false
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
            false
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
            false
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
            false
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
            false
        );
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newRaffle.initialize(data);
    }

    function test_UserCanPurchaseTicket() external{
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

    function test_UserCanPurchaseTicketTwice() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(1);

        changePrank(alice);

        mockERC20.mint(alice, 100e6);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(9);

        assertEq(tokenRaffle.ownerOf(0), address(0));
        assertEq(tokenRaffle.ownerOf(1), bob);
        assertEq(tokenRaffle.ownerOf(2), alice);
        uint256[] memory alicebTickets = tokenRaffle.balanceOf(alice);
        assertEq(alicebTickets.length, 9);
        assertEq(alicebTickets[0], 2);
        assertEq(alicebTickets[8], 10);
        assertEq(tokenRaffle.totalSupply(), 10);
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 1e8);
    }

        function test_UserCanPurchaseSeveralTicketsWithToken() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(10);

        assertEq(tokenRaffle.ownerOf(0), address(0));
        assertEq(tokenRaffle.ownerOf(1), bob);
        assertEq(tokenRaffle.ownerOf(10), bob);
        uint256[] memory bobTickets = tokenRaffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(tokenRaffle.totalSupply(), 10);
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 1e8);
    }

    function test_RevertWhen_UserPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
        tokenRaffle.purchaseTickets(11);
    }

    function test_RevertIf_UserNotHaveEnoughBalanceForPurchaseWithToken() external{
        changePrank(alice);
        vm.expectRevert(Errors.NOT_ENOUGH_BALANCE.selector);
        tokenRaffle.purchaseTickets(1);
    }


    function test_RevertIf_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        tokenRaffle.purchaseTickets(0);
    }

    function test_RevertIf_UserPurchaseTicketInEthInsteadOfToken() external{
        changePrank(bob);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.purchaseTicketsInEth{value: 1e18}(1);
    }

    function test_RevertIf_UserPurchaseTicketsAfterTicketSalesEnd() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        tokenRaffle.purchaseTickets(1);
    }

    function test_CorrecltyDrawnWinningTickets() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        assertFalse(tokenRaffle.winnerAddress() == address(0));
        assertTrue(tokenRaffle.winnerAddress() == bob);
    }

    function test_RevertWhen_DrawnATicketCalledOnRaffleNotEnded() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        tokenRaffle.drawnTickets();
    }

    function test_StatusBackToInitRandomNumberTicketDrawnedIsZero() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.requestRandomNumberReturnZero(requestId);
        assertTrue(tokenRaffle.raffleStatus() == RaffleDataTypes.RaffleStatus.Init);
    }

    function test_RevertWhen_DrawnATicketCalledButAlreadyDrawn() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
        tokenRaffle.drawnTickets();
    }

    function test_UserCanClaimHisPrice() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
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

    function test_RevertIf_UserCallClaimPriceWhenRaffleStillOpen() external{
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        tokenRaffle.winnerClaimPrice();
    }

    function test_RevertWhen_NotWinnerTryToCallWinnerClaimPrice() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(10);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
        tokenRaffle.winnerClaimPrice();
    }

    function test_RevertWhen_UserClaimPriceButDrawnHasNotBeDone() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        tokenRaffle.winnerClaimPrice();
    }

    function test_CorrectlyClaimTokenTicketSalesAmount() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        uint256 aliceBalanceBefore = mockERC20.balanceOf(alice);
        uint256 treasuryBalanceBefore = mockERC20.balanceOf(treasury);
        uint256 totalSalesAmount = 2e7;
        tokenRaffle.claimTokenTicketSalesAmount();
        assertEq(mockERC20.balanceOf(treasury), treasuryBalanceBefore + totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(mockERC20.balanceOf(alice), aliceBalanceBefore + totalSalesAmount - totalSalesAmount.percentMul(FEE_PERCENTAGE));
        assertEq(mockERC20.balanceOf(address(tokenRaffle)), 0);
    }

    function test_RevertIf_CreatorClaimEthTicketSalesAmountInsteadOfToken() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        changePrank(alice);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.claimEthTicketSalesAmount();
    }

    function test_RevertIf_NotCreatorClaimTokenTicketSalesAmount() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffle.drawnTickets();
        uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
        mockRamdomProvider.generateRandomNumbers(requestId);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenRaffle.claimTokenTicketSalesAmount();
    }

    function test_RevertIf_WinningTicketNotDrawnBeforeClaimingTicketSalesAmount() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffle), 100e6);
        tokenRaffle.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        changePrank(alice);
        vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
        tokenRaffle.claimTokenTicketSalesAmount();
    }

    function test_CreatorCanCallInsuranceAndGetPartOfInsuranceIfNotTicketHasBeenSold() external{
        changePrank(carole);
        uint256 caroleBalanceBefore = mockERC20.balanceOf(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffleWithInsurance.creatorExerciseTokenInsurance();
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);
        uint256 insurancePaid = tokenRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(mockERC20.balanceOf(treasury),treasuryAmount);
        uint256 expectedCaroleBalance = caroleBalanceBefore + insurancePaid - treasuryAmount;
        assertEq(mockERC20.balanceOf(carole),expectedCaroleBalance);
    }

    function test_CreatorCanCallInsuranceAfterDrawnTicketCall() external{
        changePrank(carole);
        uint256 caroleBalanceBefore = mockERC20.balanceOf(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffleWithInsurance.drawnTickets();
        tokenRaffleWithInsurance.creatorExerciseTokenInsurance();
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);
        uint256 insurancePaid = tokenRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(mockERC20.balanceOf(treasury),treasuryAmount);
        uint256 expectedCaroleBalance = caroleBalanceBefore + insurancePaid - treasuryAmount;
        assertEq(mockERC20.balanceOf(carole),expectedCaroleBalance);
    }

    function test_CreatorCanCallInsuranceAndDontGetPartOfInsuranceIfTicketHasBeenSold() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(2);
        changePrank(carole);
        uint256 caroleBalanceBefore = mockERC20.balanceOf(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffleWithInsurance.creatorExerciseTokenInsurance();
        assertEq(mockERC721.ownerOf(tokenWithAssuranceNftId), carole);
        uint256 insurancePaid = tokenRaffleWithInsurance.insurancePaid();
        uint256 treasuryAmount = insurancePaid.percentMul(FEE_PERCENTAGE);
        assertEq(mockERC20.balanceOf(treasury),treasuryAmount);
        assertEq(mockERC20.balanceOf(carole),caroleBalanceBefore);
    }

    function test_RevertIf_CreatorCallExerciceEthInsuranceWhenItsTokenRaffe() external{
        changePrank(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffleWithInsurance.creatorExerciseEthInsurance();
    }

    function test_RevertIf_CreatorAlreadyExerciceInsurance() external{
        changePrank(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffleWithInsurance.creatorExerciseTokenInsurance();
        vm.expectRevert();
        tokenRaffleWithInsurance.creatorExerciseTokenInsurance();
    }

    function test_RevertIf_NotCreatorCallExerciseTokenInsurance() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_CREATOR.selector);
        tokenRaffleWithInsurance.creatorExerciseTokenInsurance();
    }

    function test_RevertIf_CreatorExerciseTokenInsuranceWhereTicketSalesAreEqualOrHigherThanInsurance() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(5);

        changePrank(carole);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        tokenRaffleWithInsurance.creatorExerciseTokenInsurance();
    }
    
    function test_UserCanGetRefundsWithInsurancePart() external {
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        uint256 bobPrevBalance = mockERC20.balanceOf(bob);
        tokenRaffleWithInsurance.userExerciseTokenInsuranceRefund();

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

    function test_RevertWhen_UserClaimEthInsuranceRefundOnATokenRaffle() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffleWithInsurance.userExerciseEthInsuranceRefund();
    }

    function test_RevertWhen_UserClaimTokenInsuranceRefundOnTicketSupplyGreaterThanMinInsuranceSales() external{
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(5);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.SALES_EXCEED_INSURANCE_LIMIT.selector);
        tokenRaffleWithInsurance.userExerciseTokenInsuranceRefund();
    }

    function test_RevertWhen_UserAlreadyClaimRefundsWithInsurancePart() external {
        changePrank(bob);
        mockERC20.approve(address(tokenRaffleWithInsurance), 100e6);
        tokenRaffleWithInsurance.purchaseTickets(2);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        tokenRaffleWithInsurance.userExerciseTokenInsuranceRefund();
        vm.expectRevert(Errors.ALREADY_CLAIMED.selector);
        tokenRaffleWithInsurance.userExerciseTokenInsuranceRefund();
    }

    function test_RevertWhen_UserDidntPurchaseTicketAndClaimRefund() external {
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
        vm.expectRevert(Errors.NOTHING_TO_CLAIM.selector);
        tokenRaffleWithInsurance.userExerciseTokenInsuranceRefund();
    }
}
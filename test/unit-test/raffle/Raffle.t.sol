// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockRandomProvider} from "../../../src/mocks/MockRandomProvider.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {NFTCollectionWhitelist} from "../../../src/core/NFTCollectionWhitelist.sol";
import {TokenWhitelist} from "../../../src/core/TokenWhitelist.sol";
import {ConfigManager} from "../../../src/core/ConfigManager.sol";

import {Raffle} from "../../../src/raffle/Raffle.sol";
import {RaffleDataTypes} from "../../../src/raffle/RaffleDataTypes.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";
import {ConfiguratorInputTypes} from "../../../src/libraries/types/ConfiguratorInputTypes.sol";
import {PercentageMath} from "../../../src/libraries/math/PercentageMath.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

contract RaffleTest is Test, SetupUsers {
    using PercentageMath for uint;
    MockERC20  mockERC20;
    MockERC721 mockERC721;
    MockRandomProvider mockRamdomProvider;
    ConfigManager configManager;


    Raffle tokenRaffle;
    Raffle ethRaffle;
    ImplementationManager implementationManager;
    NFTCollectionWhitelist nftCollectionWhitelist;
    TokenWhitelist tokenWhitelist;
    AccessController accessController;
    
    uint256 maxTicketSupply = 10;
    uint256 tokenNftId = 1;
    uint256 ethNftId = 2;
    uint256 tokenTicketPrice = 1e7; // 10
    uint256 ethTicketPrice = 1e18; // 10
    uint64 ticketSaleDuration = 1 days;

    uint256 MIN_SALE_DURATION = 1 days;
    uint256 MAX_SALE_DURATION = 2 weeks;
    uint256 MAX_TICKET_SUPPLY = 10000;
    uint256 FEE_PERCENTAGE = 1e2;

    function setUp() public virtual override {
       SetupUsers.setUp();

       mockERC20 = new MockERC20("Mocked USDC", "USDC", 6);
       mockERC20.mint(bob, 100e6);
       mockERC721 = new MockERC721("Mocked NFT", "NFT");
       mockERC721.mint(alice, tokenNftId);
       mockERC721.mint(alice, ethNftId);
       
       changePrank(deployer);
       accessController = new AccessController(maintainer);
       implementationManager = new ImplementationManager(address(accessController));
       nftCollectionWhitelist = new NFTCollectionWhitelist(implementationManager);
       tokenWhitelist = new TokenWhitelist(implementationManager);
       
       ConfiguratorInputTypes.InitConfigManagerInput memory configData = ConfiguratorInputTypes.InitConfigManagerInput(
            FEE_PERCENTAGE,
            MAX_TICKET_SUPPLY,
            MIN_SALE_DURATION,
            MAX_SALE_DURATION
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
              admin
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
              tokenTicketPrice,
              ticketSaleDuration,
              false
       );
       mockERC721.transferFrom(alice, address(tokenRaffle), tokenNftId);
       tokenRaffle.initialize(raffleData);
       
       ethRaffle = new Raffle();
       RaffleDataTypes.InitRaffleParams memory ethData = RaffleDataTypes.InitRaffleParams(
              implementationManager,
              IERC20(address(0)),
              mockERC721,
              alice,
              ethNftId,
              maxTicketSupply,
              ethTicketPrice,
              ticketSaleDuration,
              true
       );
       mockERC721.transferFrom(alice, address(ethRaffle), ethNftId);
       ethRaffle.initialize(ethData);
    }

    function test_TokenRaffleCorrecltyInitialize() external{
       assertEq(tokenRaffle.creator(), alice);
       assertEq(tokenRaffle.ticketPrice(), tokenTicketPrice);
       assertEq(tokenRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
       assertEq(tokenRaffle.totalSupply(), 0);
       assertEq(tokenRaffle.maxSupply(), maxTicketSupply);
       assertFalse(tokenRaffle.isETHTokenSales());
       assertEq(address(tokenRaffle.purchaseCurrency()), address(mockERC20));
       (IERC721 contractAddress, uint256 id )= tokenRaffle.nftToWin();
       assertEq(address(contractAddress) ,address(mockERC721));
       assertEq(id ,tokenNftId);
       assertEq(contractAddress.ownerOf(tokenNftId) ,address(tokenRaffle));
    }

    function test_ETHRaffleCorrecltyInitialize() external{
       assertEq(ethRaffle.creator(), alice);
       assertEq(ethRaffle.ticketPrice(), ethTicketPrice);
       assertEq(ethRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
       assertEq(ethRaffle.totalSupply(), 0);
       assertEq(ethRaffle.maxSupply(), maxTicketSupply);
       assertTrue(ethRaffle.isETHTokenSales());
       assertEq(address(ethRaffle.purchaseCurrency()), address(0));
       (IERC721 contractAddress, uint256 id )= ethRaffle.nftToWin();
       assertEq(address(contractAddress) ,address(mockERC721));
       assertEq(id ,ethNftId);
       assertEq(contractAddress.ownerOf(ethNftId) ,address(ethRaffle));
    }
   
   function test_RevertIf_RaffleAlreadyInitialize() external{
       RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
              implementationManager,
              mockERC20,
              mockERC721,
              alice,
              tokenNftId,
              maxTicketSupply,
              tokenTicketPrice,
              ticketSaleDuration,
              false
       );
       vm.expectRevert("Initializable: contract is already initialized");
       tokenRaffle.initialize(data);
   }

   function test_RevertIf_RaffleInitializeDataNotCorrect() external{
       uint _nftId = 3;
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
              tokenTicketPrice,
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
              tokenTicketPrice,
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
              tokenTicketPrice,
              ticketSaleDuration,
              false
       );
       vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
       newRaffle.initialize(data);

       // tokenTicketPrice == 0
       data = RaffleDataTypes.InitRaffleParams(
              implementationManager,
              mockERC20,
              mockERC721,
              alice,
              _nftId,
              maxTicketSupply,
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
              tokenTicketPrice,
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
              tokenTicketPrice,
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
              tokenTicketPrice,
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
              tokenTicketPrice,
              uint64(MAX_SALE_DURATION) + 1,
              false
       );
       vm.expectRevert(Errors.OUT_OF_RANGE.selector);
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

    function test_UserCanPurchaseTicketInETH() external{
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

    function test_UserCanPurchaseSeveralTickets() external{
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
        
       vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
       ethRaffle.purchaseTicketsInEth(11);
   }

   function test_RevertIf_UserNotHaveEnoughBalanceForPurchase() external{
        changePrank(alice);
        vm.expectRevert(Errors.NOT_ENOUGH_BALANCE.selector);
        tokenRaffle.purchaseTickets(1);
        vm.expectRevert(Errors.NOT_ENOUGH_BALANCE.selector);
        ethRaffle.purchaseTicketsInEth(1);
   }

   function test_RevertIf_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        tokenRaffle.purchaseTickets(0);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        ethRaffle.purchaseTicketsInEth(0);

   }

   function test_RevertIf_UserPurchaseTicketInEthInsteadOfToken() external{
        changePrank(bob);
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        tokenRaffle.purchaseTicketsInEth(1);
   }

   function test_RevertIf_UserPurchaseTicketInTokeInsteadOfEth() external{
        changePrank(bob);
        vm.expectRevert(Errors.IS_ETH_RAFFLE.selector);
        ethRaffle.purchaseTickets(1);
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
       assertFalse(tokenRaffle.raffleStatus() == RaffleDataTypes.RaffleStatus.Init);
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
     vm.store(address(tokenRaffle),bytes32(uint256(11)), bytes32(winningTicketNumber));
     assertEq(tokenRaffle.winningTicket(), winningTicketNumber);
     tokenRaffle.claimPrice();
     assertEq(mockERC721.ownerOf(tokenNftId),bob);
     assertEq(tokenRaffle.winnerAddress(), bob);
   }

   function test_RevertIf_UserCallClaimPriceWhenRaffleStillOpen() external{
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        tokenRaffle.claimPrice();
   }

   function test_RevertWhen_NotWinnerTryToCallClaimPrice() external{
          changePrank(bob);
          mockERC20.approve(address(tokenRaffle), 100e6);
          tokenRaffle.purchaseTickets(10);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          tokenRaffle.drawnTickets();
          uint256 requestId = mockRamdomProvider.callerToRequestId(address(tokenRaffle));
          mockRamdomProvider.generateRandomNumbers(requestId);
          changePrank(alice);
          vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
          tokenRaffle.claimPrice();
   }

   function test_RevertWhen_UserClaimPriceButDrawnHasNotBeDone() external{
          changePrank(bob);
          mockERC20.approve(address(tokenRaffle), 100e6);
          tokenRaffle.purchaseTickets(2);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
          tokenRaffle.claimPrice();
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
          uint256 treasuryBalanceBefore = mockERC20.balanceOf(admin);
          uint256 totalSalesAmount = 2e7;
          tokenRaffle.claimTokenTicketSalesAmount();
          assertEq(mockERC20.balanceOf(admin), treasuryBalanceBefore + totalSalesAmount.percentMul(FEE_PERCENTAGE));
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
          tokenRaffle.claimETHTicketSalesAmount();
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
   
  function test_CorrectlyClaimETHTicketSalesAmount() external{
          changePrank(bob);
          ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          ethRaffle.drawnTickets();
          uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
          mockRamdomProvider.generateRandomNumbers(requestId);
          changePrank(alice);
          uint256 aliceBalanceBefore = alice.balance;
          uint256 treasuryBalanceBefore = admin.balance;
          uint256 totalSalesAmount = 2e18;
          ethRaffle.claimETHTicketSalesAmount();
          assertEq(admin.balance, treasuryBalanceBefore + totalSalesAmount.percentMul(FEE_PERCENTAGE));
          assertEq(alice.balance, aliceBalanceBefore + totalSalesAmount - totalSalesAmount.percentMul(FEE_PERCENTAGE));
          assertEq(address(ethRaffle).balance, 0);
   }

   function test_RevertIf_CreatorClaimTokenTicketSalesAmountInsteadOfETH() external{
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

   function test_RevertIf_NotCreatorClaimETHTicketSalesAmount() external{
           changePrank(bob);
          ethRaffle.purchaseTicketsInEth{value: 2e18}(2);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          ethRaffle.drawnTickets();
          uint256 requestId = mockRamdomProvider.callerToRequestId(address(ethRaffle));
          mockRamdomProvider.generateRandomNumbers(requestId);
          vm.expectRevert(Errors.NOT_CREATOR.selector);
          ethRaffle.claimETHTicketSalesAmount();
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
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockRandomProvider} from "../../../src/mocks/MockRandomProvider.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {Raffle} from "../../../src/raffle/Raffle.sol";
import {RaffleDataTypes} from "../../../src/raffle/RaffleDataTypes.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

contract RaffleTest is Test, SetupUsers {

    MockERC20  mockERC20;
    MockERC721 mockERC721;
    MockRandomProvider mockRamdomProvider;

    Raffle raffle;
    ImplementationManager implementationManager;
    AccessController accessController;
    
    uint256 maxTicketSupply = 10;
    uint256 nftId = 1;
    uint256 ticketPrice = 1e7; // 10
    uint64 ticketSaleDuration = 24*60*60;
    
    function setUp() public virtual override {
       SetupUsers.setUp();

       mockERC20 = new MockERC20("Mocked USDC", "USDC", 6);
       mockERC20.mint(bob, 100e6);
       mockERC721 = new MockERC721("Mocked NFT", "NFT");
       mockERC721.mint(alice, nftId);
       
       changePrank(deployer);
       accessController = new AccessController(maintainer);
       implementationManager = new ImplementationManager(address(accessController));
       
       raffle = new Raffle();
       RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
              implementationManager,
              mockERC20,
              mockERC721,
              alice,
              nftId,
              maxTicketSupply,
              ticketPrice,
              ticketSaleDuration
       );
       changePrank(alice);
       mockERC721.transferFrom(alice, address(raffle), nftId);
       raffle.initialize(data);
       
       mockRamdomProvider = new MockRandomProvider(raffle);
       changePrank(maintainer);
       implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.RandomProvider,
              address(mockRamdomProvider)
       );
       implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.RaffleContract,
              address(raffle)
       );
    }

    function test_RaffleCorrecltyInitialize() external{
       changePrank(alice);
       Raffle initRaffle = new Raffle();
       RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
              implementationManager,
              mockERC20,
              mockERC721,
              alice,
              2,
              maxTicketSupply,
              ticketPrice,
              ticketSaleDuration
       );
       mockERC721.mint(alice, 2);
       mockERC721.transferFrom(alice, address(initRaffle), 2);
       initRaffle.initialize(data);
       assertEq(initRaffle.creator(), alice);
       assertEq(initRaffle.ticketPrice(), ticketPrice);
       assertEq(initRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
       assertEq(initRaffle.totalSupply(), 0);
       assertEq(initRaffle.maxSupply(), maxTicketSupply);
       assertEq(address(initRaffle.purchaseCurrency()), address(mockERC20));
       (IERC721 contractAddress, uint256 id )= initRaffle.nftToWin();
       assertEq(address(contractAddress) ,address(mockERC721));
       assertEq(id ,2);
       assertEq(contractAddress.ownerOf(2) ,address(initRaffle));
    }
   
   function test_RevertIf_RaffleAlreadyInitialize() external{
       RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
              implementationManager,
              mockERC20,
              mockERC721,
              alice,
              nftId,
              maxTicketSupply,
              ticketPrice,
              ticketSaleDuration
       );
       vm.expectRevert("Initializable: contract is already initialized");
       raffle.initialize(data);
   }

    function test_UserCanPurchaseTicket() external{
       changePrank(bob);
       
       mockERC20.approve(address(raffle), 100e6);
       
       raffle.purchaseTickets(1);
       
       assertEq(raffle.ownerOf(0), bob);
       uint256[] memory bobTickets = raffle.balanceOf(bob);
       assertEq(bobTickets.length, 1);
       assertEq(bobTickets[0], 0);
       assertEq(raffle.totalSupply(), 1);
       assertEq(mockERC20.balanceOf(address(raffle)), 1e7);
    }
    
    function test_UserCanPurchaseTicketTwice() external{
       changePrank(bob);
       mockERC20.approve(address(raffle), 100e6);
       raffle.purchaseTickets(1);

       changePrank(alice);

       mockERC20.mint(alice, 100e6);
       mockERC20.approve(address(raffle), 100e6);
       raffle.purchaseTickets(9);
       assertEq(raffle.ownerOf(0), bob);
       assertEq(raffle.ownerOf(1), alice);
       uint256[] memory alicebTickets = raffle.balanceOf(alice);
       assertEq(alicebTickets.length, 9);
       assertEq(alicebTickets[0], 1);
       assertEq(alicebTickets[8], 9);
       assertEq(raffle.totalSupply(), 10);
       assertEq(mockERC20.balanceOf(address(raffle)), 1e8);
    }

    function test_UserCanPurchaseSeveralTickets() external{
        changePrank(bob);
        mockERC20.approve(address(raffle), 100e6);
        raffle.purchaseTickets(10);
        assertEq(raffle.ownerOf(0), bob);
        assertEq(raffle.ownerOf(9), bob);
        uint256[] memory bobTickets = raffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 0);
        assertEq(bobTickets[9], 9);
        assertEq(raffle.totalSupply(), 10);
        assertEq(mockERC20.balanceOf(address(raffle)), 1e8);
    }

   function test_RevertWhen_UserPurchaseMakeTicketSupplyExceedMaxSupply() external{
        changePrank(bob);
        mockERC20.approve(address(raffle), 100e6);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
        raffle.purchaseTickets(11);
   }

   function test_RevertIf_UserNotHaveEnoughBalanceForPurchase() external{
        changePrank(alice);
        vm.expectRevert(Errors.NOT_ENOUGH_BALANCE.selector);
        raffle.purchaseTickets(1);
   }

   function test_RevertIf_UserPurchaseZeroTicket() external{
        changePrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        raffle.purchaseTickets(0);
   }

   function test_RevertIf_UserPurchaseTicketsAfterTicketSalesEnd() external{
        changePrank(bob);
        vm.warp(uint64(block.timestamp) + ticketSaleDuration);
        vm.expectRevert(Errors.RAFFLE_CLOSE.selector);
        raffle.purchaseTickets(1);
   }


   function test_DrawnATicket() external{
       changePrank(bob);
       mockERC20.approve(address(raffle), 100e6);
       raffle.purchaseTickets(2);
       vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
       raffle.drawnRandomTickets();
       assertFalse(raffle.winnerAddress() == address(0));
   }


   function test_RevertWhen_DrawnATicketCalledOnRaffleNotEnded() external{
       changePrank(bob);
       mockERC20.approve(address(raffle), 100e6);
       raffle.purchaseTickets(2);
       vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
       raffle.drawnRandomTickets();
   }

   function test_RevertWhen_DrawnATicketRandomNumberIsZero() external{
       changePrank(bob);
       mockERC20.approve(address(raffle), 100e6);
       raffle.purchaseTickets(2);
       vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
       vm.expectRevert(Errors.CANT_BE_ZERO.selector);
       mockRamdomProvider.requestRandomNumberReturnZero();
   }

   function test_RevertWhen_DrawnATicketCalledButAlreadyDrawn() external{
       changePrank(bob);
       mockERC20.approve(address(raffle), 100e6);
       raffle.purchaseTickets(2);
       vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
       raffle.drawnRandomTickets();
       vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
       raffle.drawnRandomTickets();
   }


   function test_UserCanClaimHisPrice() external{
     changePrank(bob);
     mockERC20.approve(address(raffle), 100e6);
     raffle.purchaseTickets(2);
     vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
     raffle.drawnRandomTickets();
     uint256 winningTicketNumber = 1;
     vm.store(address(raffle),bytes32(uint256(10)), bytes32(winningTicketNumber));
     assertEq(raffle.winningTicket(), winningTicketNumber);
     raffle.claimPrice();
     assertEq(mockERC721.ownerOf(nftId),bob);
     assertEq(raffle.winnerAddress(), bob);
     assertEq(raffle.winningTicket(), 1);
   }

   function test_RevertIf_UserCallClaimPriceWhenRaffleStillOpen() external{
        vm.expectRevert(Errors.RAFFLE_STILL_OPEN.selector);
        raffle.claimPrice();
   }

   function test_RevertWhen_NotWinnerTryToCallClaimPrice() external{
          changePrank(bob);
          mockERC20.approve(address(raffle), 100e6);
          raffle.purchaseTickets(2);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          raffle.drawnRandomTickets();
          changePrank(alice);
          vm.expectRevert(Errors.MSG_SENDER_NOT_WINNER.selector);
          raffle.claimPrice();
   }

   function test_RevertWhen_UserClaimPriceButDrawnHasNotBeDone() external{
          changePrank(bob);
          mockERC20.approve(address(raffle), 100e6);
          raffle.purchaseTickets(2);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
          raffle.claimPrice();
   }


   function test_CorrectlyClaimTicketSalesAmount() external{
          changePrank(bob);
          mockERC20.approve(address(raffle), 100e6);
          raffle.purchaseTickets(2);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          raffle.drawnRandomTickets();
          changePrank(alice);
          uint256 aliceBalanceBefore = mockERC20.balanceOf(alice);
          raffle.claimTicketSalesAmount();
          assertEq(mockERC20.balanceOf(alice), aliceBalanceBefore + 2e7);
          assertEq(mockERC20.balanceOf(address(raffle)), 0);
   }

   function test_RevertIf_NotCreatorClaimTicketSalesAmount() external{
          changePrank(bob);
          mockERC20.approve(address(raffle), 100e6);
          raffle.purchaseTickets(2);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          raffle.drawnRandomTickets();
          vm.expectRevert(Errors.NOT_CREATOR.selector);
          raffle.claimTicketSalesAmount();
   }

   function test_RevertIf_WinningTicketNotDrawnBeforeClaimingTicketSalesAmount() external{
          changePrank(bob);
          mockERC20.approve(address(raffle), 100e6);
          raffle.purchaseTickets(2);
          vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
          changePrank(alice);
          vm.expectRevert(Errors.TICKET_NOT_DRAWN.selector);
          raffle.claimTicketSalesAmount();
   }
}
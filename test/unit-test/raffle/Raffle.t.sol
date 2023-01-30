// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "@mocks/MockERC20.sol";
import {MockERC721} from "@mocks/MockERC721.sol";

import {Raffle} from "@raffle/Raffle.sol";
import {RaffleDataTypes} from "@raffle/RaffleDataTypes.sol";
import {Errors} from "@libraries/helpers/Errors.sol";

import {Utils} from "@test/utils/Utils.sol";
import {SetupUsers} from "@test/utils/SetupUsers.sol";


contract RaffleTest is Test, SetupUsers {

    MockERC20 public mockERC20;
    MockERC721 public mockERC721;

    Raffle public raffle;
    
    uint256 maxTicketSupply = 10;
    uint256 nftId = 1;
    uint256 ticketPrice = 1e7; // 10
    uint64 endTime = 24*60*60;
    
    function setUp() public virtual override {
        SetupUsers.setUp();

        mockERC20 = new MockERC20("Mocked USDC", "USDC", 6);
        mockERC20.mint(bob, 100e6);
        mockERC721 = new MockERC721("Mocked NFT", "NFT");
        mockERC721.mint(alice, nftId);
  
        raffle = new Raffle();
         RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
            alice,
            mockERC20,
            mockERC721,
            nftId,
            maxTicketSupply,
            ticketPrice,
            endTime
        );
        vm.prank(alice);
        mockERC721.approve(address(raffle), nftId);
        raffle.initialize(data);
        
    }

    function test_RaffleCorrecltyInitialize() external{
          Raffle initRaffle = new Raffle();
          RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
               alice,
               mockERC20,
               mockERC721,
               2,
               maxTicketSupply,
               ticketPrice,
               endTime
          );
          mockERC721.mint(alice, 2);
          vm.prank(alice);
          mockERC721.approve(address(initRaffle), 2);
          initRaffle.initialize(data);
          assertEq(initRaffle.creator(), alice);
          assertEq(initRaffle.ticketPrice(), ticketPrice);
          assertEq(initRaffle.endTime(), uint64(block.timestamp) + endTime);
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
            alice,
            mockERC20,
            mockERC721,
            nftId,
            maxTicketSupply,
            ticketPrice,
            endTime
        );
        vm.expectRevert("Initializable: contract is already initialized");
        raffle.initialize(data);
   }

    function test_UserCanPurchaseTicket() external{
          vm.startPrank(bob);
          
          mockERC20.approve(address(raffle), 100e6);
          
          raffle.purchaseTicket(1);
          
          assertEq(raffle.ownerOf(0), address(0));
          assertEq(raffle.ownerOf(1), bob);
          uint256[] memory bobTickets = raffle.balanceOf(bob);
          assertEq(bobTickets.length, 1);
          assertEq(bobTickets[0], 1);
          assertEq(raffle.totalSupply(), 1);
          assertEq(mockERC20.balanceOf(address(raffle)), 1e7);
    }
    
    function test_UserCanPurchaseTicketTwice() external{
          vm.startPrank(bob);
          
          mockERC20.approve(address(raffle), 100e6);
          
          raffle.purchaseTicket(1);
          vm.stopPrank();

          vm.startPrank(alice);
          mockERC20.mint(alice, 100e6);
          mockERC20.approve(address(raffle), 100e6);
          raffle.purchaseTicket(9);
          assertEq(raffle.ownerOf(0), address(0));
          assertEq(raffle.ownerOf(2), alice);
          uint256[] memory alicebTickets = raffle.balanceOf(alice);
          assertEq(alicebTickets.length, 9);
          assertEq(alicebTickets[0], 2);
          assertEq(alicebTickets[8], 10);
          assertEq(raffle.totalSupply(), 10);
          assertEq(mockERC20.balanceOf(address(raffle)), 1e8);
    }

    function test_UserCanPurchaseSeveralTickets() external{
        vm.startPrank(bob);
        mockERC20.approve(address(raffle), 100e6);
        raffle.purchaseTicket(10);
        assertEq(raffle.ownerOf(1), bob);
        assertEq(raffle.ownerOf(10), bob);
        uint256[] memory bobTickets = raffle.balanceOf(bob);
        assertEq(bobTickets.length, 10);
        assertEq(bobTickets[0], 1);
        assertEq(bobTickets[9], 10);
        assertEq(raffle.totalSupply(), 10);
        assertEq(mockERC20.balanceOf(address(raffle)), 1e8);
    }

   function test_RevertWhen_UserPurchaseMakeTicketSupplyExceedMaxSupply() external{
        vm.startPrank(bob);
        mockERC20.approve(address(raffle), 100e6);
        vm.expectRevert(Errors.MAX_TICKET_SUPPLY_EXCEEDED.selector);
        raffle.purchaseTicket(11);
   }

   function test_RevertIf_UserNotHaveEnoughBalanceForPurchase() external{
        vm.startPrank(alice);
        vm.expectRevert(Errors.NOT_ENOUGH_BALANCE.selector);
        raffle.purchaseTicket(1);
   }

   function test_RevertIf_UserPurchaseZeroTicket() external{
        vm.startPrank(bob);
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        raffle.purchaseTicket(0);
   }

   function test_RevertIf_UserPurchaseTicketsAfterEndTime() external{
        vm.startPrank(bob);
        vm.warp(uint64(block.timestamp) + endTime);
        vm.expectRevert(Errors.TIME_EXCEEDED.selector);
        raffle.purchaseTicket(1);
   }
}
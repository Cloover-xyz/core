// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";
import {MockRandomProvider} from "../../../src/mocks/MockRandomProvider.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {NFTCollectionWhitelist} from "../../../src/core/NFTCollectionWhitelist.sol";

import {Raffle} from "../../../src/raffle/Raffle.sol";
import {RaffleFactory} from "../../../src/raffle/RaffleFactory.sol";
import {RaffleDataTypes} from "../../../src/raffle/RaffleDataTypes.sol";
import {IRaffleFactory} from "../../../src/interfaces/IRaffleFactory.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

contract RaffleFactoryTest is Test, SetupUsers {

    MockERC20  mockERC20;
    MockERC721 mockERC721;
    MockRandomProvider mockRamdomProvider;

    RaffleFactory factory;
    Raffle raffle;
    ImplementationManager implementationManager;
    NFTCollectionWhitelist nftCollectionWhitelist;
    AccessController accessController;
    
    uint256 maxTicketSupply = 10;
    uint256 nftIdOne = 1;
    uint256 nftIdTwo = 2;
    
    uint256 ticketPrice = 1e7; // 10
    uint64 ticketSaleDuration = 24*60*60;
    
    function setUp() public virtual override {
      SetupUsers.setUp();

      mockERC20 = new MockERC20("Mocked USDC", "USDC", 6);
      mockERC20.mint(bob, 1000e6);
      mockERC721 = new MockERC721("Mocked NFT", "NFT");
      mockERC721.mint(alice, nftIdOne);

      
      changePrank(deployer);
      accessController = new AccessController(maintainer);
      implementationManager = new ImplementationManager(address(accessController));
      nftCollectionWhitelist = new NFTCollectionWhitelist(implementationManager);
      factory = new RaffleFactory(implementationManager);
      mockRamdomProvider = new MockRandomProvider(implementationManager);
      
      changePrank(maintainer);
      implementationManager.changeImplementationAddress(
         ImplementationInterfaceNames.RaffleFactory,
         address(factory)
      );
      implementationManager.changeImplementationAddress(
         ImplementationInterfaceNames.NFTWhitelist,
         address(nftCollectionWhitelist)
      );
      implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.RandomProvider,
              address(mockRamdomProvider)
      );
      nftCollectionWhitelist.addToWhitelist(address(mockERC721), admin);

    }

    function test_RaffleCorrecltyInitialize() external {
      changePrank(alice);

      IRaffleFactory.Params memory params = IRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         ticketSaleDuration
      );
      mockERC721.approve(address(factory), nftIdOne);
      raffle = factory.createNewRaffle(params);
      
      assertTrue(factory.isRegisteredRaffle(address(raffle)));
      assertEq(raffle.creator(), alice);
      assertEq(raffle.ticketPrice(), ticketPrice);
      assertEq(raffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(raffle.totalSupply(), 0);
      assertEq(raffle.maxSupply(), maxTicketSupply);
      assertEq(address(raffle.purchaseCurrency()), address(mockERC20));
      (IERC721 contractAddress, uint256 id )= raffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(raffle));
    }

   function test_CorrectlyRequestRandomNumberForARaffle() external {
      changePrank(alice);

      IRaffleFactory.Params memory params = IRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         ticketSaleDuration
      );
      mockERC721.approve(address(factory), nftIdOne);
      raffle = factory.createNewRaffle(params);

      changePrank(bob);
      mockERC20.approve(address(raffle), 100e6);
      raffle.purchaseTickets(2);
      vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
      assertFalse(raffle.raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned);
  
      address[] memory raffleContract = new address[](1);
      raffleContract[0] = address(raffle);
      factory.batchRaffleDrawnTickets(raffleContract);

      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffle));
      mockRamdomProvider.generateRandomNumbers(requestId);
      assertTrue(raffle.raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned);
   }
   
   function test_CorrectlyRequestRandomNumberForSeveralRaffles() external {
      mockERC721.mint(alice, nftIdTwo);
      changePrank(alice);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC721.approve(address(factory), nftIdTwo);

      IRaffleFactory.Params memory params = IRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         ticketSaleDuration
      );
      Raffle raffleOne = factory.createNewRaffle(params);
      
      params.nftId = nftIdTwo;
      Raffle raffleTwo = factory.createNewRaffle(params);

      changePrank(bob);
      mockERC20.approve(address(raffleOne), 100e6);
      raffleOne.purchaseTickets(2);
      mockERC20.approve(address(raffleTwo), 100e6);
      raffleTwo.purchaseTickets(1);
      vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
      assertFalse(raffleOne.raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned);
      assertFalse(raffleTwo.raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned);
  
      address[] memory raffleContract = new address[](2);
      raffleContract[0] = address(raffleOne);
      raffleContract[1] = address(raffleTwo);
      factory.batchRaffleDrawnTickets(raffleContract);

      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffleOne));
      mockRamdomProvider.generateRandomNumbers(requestId);
      requestId = mockRamdomProvider.callerToRequestId(address(raffleTwo));
      mockRamdomProvider.generateRandomNumbers(requestId);
      assertTrue(raffleOne.raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned);
      assertTrue(raffleTwo.raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned);
   }

   function test_RevertIf_OneOfTheRaffleHasAlreadyBeenDrawned() external {
      mockERC721.mint(alice, nftIdTwo);
      changePrank(alice);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC721.approve(address(factory), nftIdTwo);

      IRaffleFactory.Params memory params = IRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         ticketSaleDuration
      );
      Raffle raffleOne = factory.createNewRaffle(params);
      
      params.nftId = nftIdTwo;
      Raffle raffleTwo = factory.createNewRaffle(params);

      changePrank(bob);
      mockERC20.approve(address(raffleOne), 100e6);
      raffleOne.purchaseTickets(10);
      mockERC20.approve(address(raffleTwo), 100e6);
      raffleTwo.purchaseTickets(2);

      vm.warp(uint64(block.timestamp) + ticketSaleDuration + 1);
      raffleOne.drawnTickets();
      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffleOne));
      mockRamdomProvider.generateRandomNumbers(requestId);
      raffleOne.winningTicket();
      assertTrue(raffleOne.raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned);
      assertFalse(raffleTwo.raffleStatus() == RaffleDataTypes.RaffleStatus.WinningTicketsDrawned);

      address[] memory raffleContract = new address[](2);
      raffleContract[0] = address(raffleOne);
      raffleContract[1] = address(raffleTwo);
      vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
      factory.batchRaffleDrawnTickets(raffleContract);
   }
}
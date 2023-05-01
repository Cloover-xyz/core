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
import {TokenWhitelist} from "../../../src/core/TokenWhitelist.sol";
import {ConfigManager} from "../../../src/core/ConfigManager.sol";

import {ClooverRaffle} from "../../../src/raffle/ClooverRaffle.sol";
import {ClooverRaffleFactory} from "../../../src/raffle/ClooverRaffleFactory.sol";
import {IClooverRaffleFactory} from "../../../src/interfaces/IClooverRaffleFactory.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";
import {ConfiguratorInputTypes} from "../../../src/libraries/types/ConfiguratorInputTypes.sol";
import {ClooverRaffleDataTypes} from "../../../src/libraries/types/ClooverRaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

contract ClooverRaffleFactoryTest is Test, SetupUsers {
   using InsuranceLogic for uint;

    MockERC20  mockERC20;
    MockERC721 mockERC721;
    MockRandomProvider mockRamdomProvider;

    ClooverRaffleFactory factory;
    ClooverRaffle raffle;

    ImplementationManager implementationManager;
    NFTCollectionWhitelist nftCollectionWhitelist;
    TokenWhitelist tokenWhitelist;
    AccessController accessController;
    ConfigManager configManager;
    
    uint256 maxTicketSupply = 10;
    uint256 nftIdOne = 1;
    uint256 nftIdTwo = 2;
    
    uint256 ticketPrice = 1e7; // 10
    uint64 ticketSaleDuration = 1 days;
    
   uint256 MIN_SALE_DURATION = 1 days;
   uint256 MAX_SALE_DURATION = 2 weeks;
   uint256 MAX_TICKET_SUPPLY = 10000;
   uint256 PROTOCOL_FEES_PERCENTAGE = 1e2;
   uint256 INSURANCE_SALES_PERCENTAGE = 5e2; //5%

   function setUp() public virtual override {
      SetupUsers.setUp();
      
      vm.startPrank(deployer);
      mockERC20 = new MockERC20("Mocked USDC", "USDC", 6);
      mockERC20.mint(bob, 1000e6);
      mockERC20.mint(alice, 100e6);
      mockERC721 = new MockERC721("Mocked NFT", "NFT");
      mockERC721.mint(alice, nftIdOne);
      accessController = new AccessController(maintainer);
      implementationManager = new ImplementationManager(address(accessController));
      nftCollectionWhitelist = new NFTCollectionWhitelist(implementationManager);
      tokenWhitelist = new TokenWhitelist(implementationManager);
      factory = new ClooverRaffleFactory(implementationManager);
      mockRamdomProvider = new MockRandomProvider(implementationManager);
      ConfiguratorInputTypes.InitConfigManagerInput memory configData = ConfiguratorInputTypes.InitConfigManagerInput(
         PROTOCOL_FEES_PERCENTAGE,
         MAX_TICKET_SUPPLY,
         MIN_SALE_DURATION,
         MAX_SALE_DURATION,
         INSURANCE_SALES_PERCENTAGE
      );
      configManager = new ConfigManager(implementationManager, configData);

      changePrank(maintainer);
      implementationManager.changeImplementationAddress(
         ImplementationInterfaceNames.ConfigManager,
         address(configManager)
      );
      implementationManager.changeImplementationAddress(
         ImplementationInterfaceNames.ClooverRaffleFactory,
         address(factory)
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
      nftCollectionWhitelist.addToWhitelist(address(mockERC721), admin);
      tokenWhitelist.addToWhitelist(address(mockERC20));
   }

   function test_CreateClooverRaffle_TokenClooverRaffle() external {
      changePrank(alice);
      IClooverRaffleFactory.Params memory params = IClooverRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         0,
         ticketSaleDuration,
         false,
         0,
         0
      );
      mockERC721.approve(address(factory), nftIdOne);
      raffle = factory.createNewClooverRaffle(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(raffle)));
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

   function test_CreateClooverRaffle_InsuranceTokenClooverRaffle() external {
      changePrank(alice);
      uint256 minTicketSalesInsurance = 5;
      IClooverRaffleFactory.Params memory params = IClooverRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         minTicketSalesInsurance,
         ticketSaleDuration,
         false,
         0,
         0
      );
      uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC20.approve(address(factory), insuranceCost);
      ClooverRaffle insuranceClooverRaffle = factory.createNewClooverRaffle(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(insuranceClooverRaffle)));
      assertEq(insuranceClooverRaffle.creator(), alice);
      assertEq(insuranceClooverRaffle.ticketPrice(), ticketPrice);
      assertEq(insuranceClooverRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(insuranceClooverRaffle.totalSupply(), 0);
      assertEq(insuranceClooverRaffle.maxSupply(), maxTicketSupply);
      assertEq(address(insuranceClooverRaffle.purchaseCurrency()), address(mockERC20));
      (IERC721 contractAddress, uint256 id )= insuranceClooverRaffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(insuranceClooverRaffle));
      assertEq(mockERC20.balanceOf(address(insuranceClooverRaffle)) , insuranceCost);
   }

   function test_CreateClooverRaffle_InsuranceEthClooverRaffle() external {
      changePrank(alice);
      uint256 minTicketSalesInsurance = 5;
      IClooverRaffleFactory.Params memory params = IClooverRaffleFactory.Params(
         IERC20(address(0)),
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         minTicketSalesInsurance,
         ticketSaleDuration,
         true,
         0,
         0
      );
      uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
      mockERC721.approve(address(factory), nftIdOne);
      ClooverRaffle ethClooverRaffle = factory.createNewClooverRaffle{value: insuranceCost}(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(ethClooverRaffle)));
      assertEq(ethClooverRaffle.creator(), alice);
      assertEq(ethClooverRaffle.ticketPrice(), ticketPrice);
      assertEq(ethClooverRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(ethClooverRaffle.totalSupply(), 0);
      assertEq(ethClooverRaffle.maxSupply(), maxTicketSupply);
      assertEq(ethClooverRaffle.isEthTokenSales(), true);
      assertEq(address(ethClooverRaffle.purchaseCurrency()), address(0));
      (IERC721 contractAddress, uint256 id )= ethClooverRaffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(ethClooverRaffle));
      assertEq(address(ethClooverRaffle).balance, insuranceCost);
   }

   function test_CreateClooverRaffle_EthClooverRaffle() external {
      changePrank(alice);
      IClooverRaffleFactory.Params memory params = IClooverRaffleFactory.Params(
         IERC20(address(0)),
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         0,
         ticketSaleDuration,
         true,
         0,
         0
      );
      mockERC721.approve(address(factory), nftIdOne);
      ClooverRaffle ethClooverRaffle = factory.createNewClooverRaffle(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(ethClooverRaffle)));
      assertEq(ethClooverRaffle.creator(), alice);
      assertEq(ethClooverRaffle.ticketPrice(), ticketPrice);
      assertEq(ethClooverRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(ethClooverRaffle.totalSupply(), 0);
      assertEq(ethClooverRaffle.maxSupply(), maxTicketSupply);
      assertEq(ethClooverRaffle.isEthTokenSales(), true);
      assertEq(address(ethClooverRaffle.purchaseCurrency()), address(0));
      (IERC721 contractAddress, uint256 id )= ethClooverRaffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(ethClooverRaffle));
   }

   function test_CorrectlyRequestRandomNumberForAClooverRaffle() external {
      changePrank(alice);

      IClooverRaffleFactory.Params memory params = IClooverRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         0,
         ticketSaleDuration,
         false,
         0,
         0
      );
      mockERC721.approve(address(factory), nftIdOne);
      raffle = factory.createNewClooverRaffle(params);

      changePrank(bob);
      mockERC20.approve(address(raffle), 100e6);
      raffle.purchaseTickets(2);
      utils.goForward(ticketSaleDuration + 1);
      assertFalse(raffle.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DRAWN);
  
      address[] memory raffleContract = new address[](1);
      raffleContract[0] = address(raffle);
      factory.batchClooverRaffledraw(raffleContract);

      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffle));
      mockRamdomProvider.generateRandomNumbers(requestId);
      assertTrue(raffle.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DRAWN);
   }
   
   function test_CorrectlyRequestRandomNumberForSeveralClooverRaffles() external {
      mockERC721.mint(alice, nftIdTwo);
      changePrank(alice);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC721.approve(address(factory), nftIdTwo);

      IClooverRaffleFactory.Params memory params = IClooverRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         0,
         ticketSaleDuration,
         false,
         0,
         0
      );
      ClooverRaffle raffleOne = factory.createNewClooverRaffle(params);
      
      params.nftId = nftIdTwo;
      ClooverRaffle raffleTwo = factory.createNewClooverRaffle(params);

      changePrank(bob);
      mockERC20.approve(address(raffleOne), 100e6);
      raffleOne.purchaseTickets(2);
      mockERC20.approve(address(raffleTwo), 100e6);
      raffleTwo.purchaseTickets(1);
      utils.goForward(ticketSaleDuration + 1);
      assertFalse(raffleOne.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DRAWN);
      assertFalse(raffleTwo.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DRAWN);
  
      address[] memory raffleContract = new address[](2);
      raffleContract[0] = address(raffleOne);
      raffleContract[1] = address(raffleTwo);
      factory.batchClooverRaffledraw(raffleContract);

      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffleOne));
      mockRamdomProvider.generateRandomNumbers(requestId);
      requestId = mockRamdomProvider.callerToRequestId(address(raffleTwo));
      mockRamdomProvider.generateRandomNumbers(requestId);
      assertTrue(raffleOne.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DRAWN);
      assertTrue(raffleTwo.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DRAWN);
   }

   function test_RevertIf_OneOfTheClooverRaffleHasAlreadyBeenDrawned() external {
      mockERC721.mint(alice, nftIdTwo);
      changePrank(alice);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC721.approve(address(factory), nftIdTwo);

      IClooverRaffleFactory.Params memory params = IClooverRaffleFactory.Params(
         mockERC20,
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         0,
         ticketSaleDuration,
         false,
         0,
         0
      );
      ClooverRaffle raffleOne = factory.createNewClooverRaffle(params);
      
      params.nftId = nftIdTwo;
      ClooverRaffle raffleTwo = factory.createNewClooverRaffle(params);

      changePrank(bob);
      mockERC20.approve(address(raffleOne), 100e6);
      raffleOne.purchaseTickets(10);
      mockERC20.approve(address(raffleTwo), 100e6);
      raffleTwo.purchaseTickets(2);

      utils.goForward(ticketSaleDuration + 1);
      raffleOne.draw();
      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffleOne));
      mockRamdomProvider.generateRandomNumbers(requestId);
      raffleOne.winningTicket();
      assertTrue(raffleOne.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DRAWN);
      assertFalse(raffleTwo.raffleStatus() == ClooverRaffleDataTypes.ClooverRaffleStatus.DRAWN);

      address[] memory raffleContract = new address[](2);
      raffleContract[0] = address(raffleOne);
      raffleContract[1] = address(raffleTwo);
      vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
      factory.batchClooverRaffledraw(raffleContract);
   }

   function test_DeregisterClooverRaffle() external{
      changePrank(alice);
      IClooverRaffleFactory.Params memory params = IClooverRaffleFactory.Params(
         IERC20(address(0)),
         mockERC721,
         nftIdOne,
         maxTicketSupply,
         ticketPrice,
         0,
         ticketSaleDuration,
         true,
         0,
         0
      );
      mockERC721.approve(address(factory), nftIdOne);
      ClooverRaffle ethClooverRaffle = factory.createNewClooverRaffle(params);
      assertTrue(factory.isRegisteredClooverRaffle(address(ethClooverRaffle)));
      ethClooverRaffle.cancelClooverRaffle();
      assertFalse(factory.isRegisteredClooverRaffle(address(ethClooverRaffle)));
   }
}
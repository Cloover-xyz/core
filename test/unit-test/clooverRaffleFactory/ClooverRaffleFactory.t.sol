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
import {ConfigManagerDataTypes} from "../../../src/libraries/types/ConfigManagerDataTypes.sol";
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
    
    uint16 maxTotalSupply = 10;
    uint256 nftIdOne = 1;
    uint256 nftIdTwo = 2;
    
    uint256 ticketPrice = 1e7; // 10
    uint64 ticketSaleDuration = 1 days;
    
   uint64 MIN_SALE_DURATION = 1 days;
   uint64 MAX_SALE_DURATION = 2 weeks;
   uint16 MAX_TICKET_SUPPLY = 10000;
   uint16 PROTOCOL_FEE_RATE = 1e2;
   uint16 INSURANCE_RATE = 5e2; //5%

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
      ConfigManagerDataTypes.InitConfigManagerParams memory configData = ConfigManagerDataTypes.InitConfigManagerParams(
         MAX_TICKET_SUPPLY,
         PROTOCOL_FEE_RATE,
         INSURANCE_RATE,
         MIN_SALE_DURATION,
         MAX_SALE_DURATION
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

   function test_CreateClooverRaffle_TokenRaffle() external {
      changePrank(alice);
      ClooverRaffleDataTypes.CreateRaffleParams memory params = ClooverRaffleDataTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20,
         nftContract: mockERC721,
         nftId: nftIdOne,
         ticketPrice: ticketPrice,
         ticketSalesDuration: ticketSaleDuration,
         maxTotalSupply: maxTotalSupply,
         maxTicketAllowedToPurchase: 0,
         ticketSalesInsurance: 0,
         royaltiesRate: 0
      });
      mockERC721.approve(address(factory), nftIdOne);
      raffle = factory.createNewRaffle(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(raffle)));
      assertEq(raffle.creator(), alice);
      assertEq(raffle.ticketPrice(), ticketPrice);
      assertEq(raffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(raffle.currentSupply(), 0);
      assertEq(raffle.maxTotalSupply(), maxTotalSupply);
      assertEq(address(raffle.purchaseCurrency()), address(mockERC20));
      (IERC721 contractAddress, uint256 id )= raffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(raffle));
   }

   function test_CreateClooverRaffle_InsuranceTokenClooverRaffle() external {
      changePrank(alice);
      uint16 minTicketSalesInsurance = 5;
      ClooverRaffleDataTypes.CreateRaffleParams memory params = ClooverRaffleDataTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20,
         nftContract: mockERC721,
         nftId: nftIdOne,
         ticketPrice: ticketPrice,
         ticketSalesDuration: ticketSaleDuration,
         maxTotalSupply: maxTotalSupply,
         maxTicketAllowedToPurchase: 0,
         ticketSalesInsurance: minTicketSalesInsurance,
         royaltiesRate: 0
      });
      uint256 insuranceCost = uint256(minTicketSalesInsurance).calculateInsuranceCost(ticketPrice, INSURANCE_RATE);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC20.approve(address(factory), insuranceCost);
      ClooverRaffle insuranceRaffle = factory.createNewRaffle(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(insuranceRaffle)));
      assertEq(insuranceRaffle.creator(), alice);
      assertEq(insuranceRaffle.ticketPrice(), ticketPrice);
      assertEq(insuranceRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(insuranceRaffle.currentSupply(), 0);
      assertEq(insuranceRaffle.maxTotalSupply(), maxTotalSupply);
      assertEq(address(insuranceRaffle.purchaseCurrency()), address(mockERC20));
      (IERC721 contractAddress, uint256 id )= insuranceRaffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(insuranceRaffle));
      assertEq(mockERC20.balanceOf(address(insuranceRaffle)) , insuranceCost);
   }

   function test_CreateClooverRaffle_InsuranceEthClooverRaffle() external {
      changePrank(alice);
      uint16 minTicketSalesInsurance = 5;
      ClooverRaffleDataTypes.CreateRaffleParams memory params = ClooverRaffleDataTypes.CreateRaffleParams({
         purchaseCurrency: IERC20(address(0)),
         nftContract: mockERC721,
         nftId: nftIdOne,
         ticketPrice: ticketPrice,
         ticketSalesDuration: ticketSaleDuration,
         maxTotalSupply: maxTotalSupply,
         maxTicketAllowedToPurchase: 0,
         ticketSalesInsurance: minTicketSalesInsurance,
         royaltiesRate: 0
      });
      uint256 insuranceCost = uint256(minTicketSalesInsurance).calculateInsuranceCost(ticketPrice, INSURANCE_RATE);
      mockERC721.approve(address(factory), nftIdOne);
      ClooverRaffle ethRaffle = factory.createNewRaffle{value: insuranceCost}(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(ethRaffle)));
      assertEq(ethRaffle.creator(), alice);
      assertEq(ethRaffle.ticketPrice(), ticketPrice);
      assertEq(ethRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(ethRaffle.currentSupply(), 0);
      assertEq(ethRaffle.maxTotalSupply(), maxTotalSupply);
      assertEq(ethRaffle.isEthRaffle(), true);
      assertEq(address(ethRaffle.purchaseCurrency()), address(0));
      (IERC721 contractAddress, uint256 id )= ethRaffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(ethRaffle));
      assertEq(address(ethRaffle).balance, insuranceCost);
   }

   function test_CreateClooverRaffle_EthRaffle() external {
      changePrank(alice);
      ClooverRaffleDataTypes.CreateRaffleParams memory params = ClooverRaffleDataTypes.CreateRaffleParams({
         purchaseCurrency: IERC20(address(0)),
         nftContract: mockERC721,
         nftId: nftIdOne,
         ticketPrice: ticketPrice,
         ticketSalesDuration: ticketSaleDuration,
         maxTotalSupply: maxTotalSupply,
         maxTicketAllowedToPurchase: 0,
         ticketSalesInsurance: 0,
         royaltiesRate: 0
      });
      mockERC721.approve(address(factory), nftIdOne);
      ClooverRaffle ethRaffle = factory.createNewRaffle(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(ethRaffle)));
      assertEq(ethRaffle.creator(), alice);
      assertEq(ethRaffle.ticketPrice(), ticketPrice);
      assertEq(ethRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(ethRaffle.currentSupply(), 0);
      assertEq(ethRaffle.maxTotalSupply(), maxTotalSupply);
      assertEq(ethRaffle.isEthRaffle(), true);
      assertEq(address(ethRaffle.purchaseCurrency()), address(0));
      (IERC721 contractAddress, uint256 id )= ethRaffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(ethRaffle));
   }

   function test_CorrectlyRequestRandomNumberForAClooverRaffle() external {
      changePrank(alice);
      ClooverRaffleDataTypes.CreateRaffleParams memory params = ClooverRaffleDataTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20,
         nftContract: mockERC721,
         nftId: nftIdOne,
         ticketPrice: ticketPrice,
         ticketSalesDuration: ticketSaleDuration,
         maxTotalSupply: maxTotalSupply,
         maxTicketAllowedToPurchase: 0,
         ticketSalesInsurance: 0,
         royaltiesRate: 0
      });
      mockERC721.approve(address(factory), nftIdOne);
      raffle = factory.createNewRaffle(params);

      changePrank(bob);
      mockERC20.approve(address(raffle), 100e6);
      raffle.purchaseTickets(2);
      utils.goForward(ticketSaleDuration + 1);
      assertFalse(raffle.raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN);
  
      address[] memory raffleContract = new address[](1);
      raffleContract[0] = address(raffle);
      factory.batchClooverRaffledraw(raffleContract);

      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffle));
      mockRamdomProvider.generateRandomNumbers(requestId);
      assertTrue(raffle.raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN);
   }
   
   function test_CorrectlyRequestRandomNumberForSeveralClooverRaffles() external {
      mockERC721.mint(alice, nftIdTwo);
      changePrank(alice);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC721.approve(address(factory), nftIdTwo);
      ClooverRaffleDataTypes.CreateRaffleParams memory params = ClooverRaffleDataTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20,
         nftContract: mockERC721,
         nftId: nftIdOne,
         ticketPrice: ticketPrice,
         ticketSalesDuration: ticketSaleDuration,
         maxTotalSupply: maxTotalSupply,
         maxTicketAllowedToPurchase: 0,
         ticketSalesInsurance: 0,
         royaltiesRate: 0
      });
      ClooverRaffle raffleOne = factory.createNewRaffle(params);
      
      params.nftId = nftIdTwo;
      ClooverRaffle raffleTwo = factory.createNewRaffle(params);

      changePrank(bob);
      mockERC20.approve(address(raffleOne), 100e6);
      raffleOne.purchaseTickets(2);
      mockERC20.approve(address(raffleTwo), 100e6);
      raffleTwo.purchaseTickets(1);
      utils.goForward(ticketSaleDuration + 1);
      assertFalse(raffleOne.raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN);
      assertFalse(raffleTwo.raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN);
  
      address[] memory raffleContract = new address[](2);
      raffleContract[0] = address(raffleOne);
      raffleContract[1] = address(raffleTwo);
      factory.batchClooverRaffledraw(raffleContract);

      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffleOne));
      mockRamdomProvider.generateRandomNumbers(requestId);
      requestId = mockRamdomProvider.callerToRequestId(address(raffleTwo));
      mockRamdomProvider.generateRandomNumbers(requestId);
      assertTrue(raffleOne.raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN);
      assertTrue(raffleTwo.raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN);
   }

   function test_RevertIf_OneOfTheClooverRaffleHasAlreadyBeenDrawned() external {
      mockERC721.mint(alice, nftIdTwo);
      changePrank(alice);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC721.approve(address(factory), nftIdTwo);

      ClooverRaffleDataTypes.CreateRaffleParams memory params = ClooverRaffleDataTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20,
         nftContract: mockERC721,
         nftId: nftIdOne,
         ticketPrice: ticketPrice,
         ticketSalesDuration: ticketSaleDuration,
         maxTotalSupply: maxTotalSupply,
         maxTicketAllowedToPurchase: 0,
         ticketSalesInsurance: 0,
         royaltiesRate: 0
      });
      ClooverRaffle raffleOne = factory.createNewRaffle(params);
      
      params.nftId = nftIdTwo;
      ClooverRaffle raffleTwo = factory.createNewRaffle(params);

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
      assertTrue(raffleOne.raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN);
      assertFalse(raffleTwo.raffleStatus() == ClooverRaffleDataTypes.RaffleStatus.DRAWN);

      address[] memory raffleContract = new address[](2);
      raffleContract[0] = address(raffleOne);
      raffleContract[1] = address(raffleTwo);
      vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
      factory.batchClooverRaffledraw(raffleContract);
   }

   function test_DeregisterClooverRaffle() external{
      changePrank(alice);
      ClooverRaffleDataTypes.CreateRaffleParams memory params = ClooverRaffleDataTypes.CreateRaffleParams({
         purchaseCurrency: IERC20(address(0)),
         nftContract: mockERC721,
         nftId: nftIdOne,
         ticketPrice: ticketPrice,
         ticketSalesDuration: ticketSaleDuration,
         maxTotalSupply: maxTotalSupply,
         maxTicketAllowedToPurchase: 0,
         ticketSalesInsurance: 0,
         royaltiesRate: 0
      });
      mockERC721.approve(address(factory), nftIdOne);
      ClooverRaffle ethRaffle = factory.createNewRaffle(params);
      assertTrue(factory.isRegisteredClooverRaffle(address(ethRaffle)));
      ethRaffle.cancelRaffle();
      assertFalse(factory.isRegisteredClooverRaffle(address(ethRaffle)));
   }
}
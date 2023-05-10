// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;


import {ClooverRaffle} from "src/raffle/ClooverRaffle.sol";

import {ClooverRaffleTypes} from "src/libraries/ClooverRaffleTypes.sol";

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactoryTest is IntegrationTest {

   ClooverRaffle raffle;

   uint16 maxTotalSupply = 10;
   uint256 nftIdOne = 1;
   uint256 nftIdTwo = 2;
   
   uint256 ticketPrice = 1e7; // 10
   uint64 ticketSaleDuration = 1 days;


   function setUp() public virtual override {
      super.setUp();
      
      _mintERC20(address(creator), 100e6);
      _mintERC20(address(participant1), 1000e6);
      
      _mintNFT(address(creator), nftIdOne);
   }

   function test_CreateClooverRaffle_TokenRaffle() external {
      changePrank(alice);
      ClooverRaffleTypes.CreateRaffleParams memory params = ClooverRaffleTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20WithPermit,
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
      assertEq(address(raffle.purchaseCurrency()), address(mockERC20WithPermit));
      (IERC721 contractAddress, uint256 id )= raffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(raffle));
   }

   function test_CreateClooverRaffle_InsuranceTokenClooverRaffle() external {
      changePrank(alice);
      uint16 minTicketSalesInsurance = 5;
      ClooverRaffleTypes.CreateRaffleParams memory params = ClooverRaffleTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20WithPermit,
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
      mockERC20WithPermit.approve(address(factory), insuranceCost);
      ClooverRaffle insuranceRaffle = factory.createNewRaffle(params);
      
      assertTrue(factory.isRegisteredClooverRaffle(address(insuranceRaffle)));
      assertEq(insuranceRaffle.creator(), alice);
      assertEq(insuranceRaffle.ticketPrice(), ticketPrice);
      assertEq(insuranceRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
      assertEq(insuranceRaffle.currentSupply(), 0);
      assertEq(insuranceRaffle.maxTotalSupply(), maxTotalSupply);
      assertEq(address(insuranceRaffle.purchaseCurrency()), address(mockERC20WithPermit));
      (IERC721 contractAddress, uint256 id )= insuranceRaffle.nftToWin();
      assertEq(address(contractAddress) ,address(mockERC721));
      assertEq(id ,nftIdOne);
      assertEq(contractAddress.ownerOf(nftIdOne) ,address(insuranceRaffle));
      assertEq(mockERC20WithPermit.balanceOf(address(insuranceRaffle)) , insuranceCost);
   }

   function test_CreateClooverRaffle_InsuranceEthClooverRaffle() external {
      changePrank(alice);
      uint16 minTicketSalesInsurance = 5;
      ClooverRaffleTypes.CreateRaffleParams memory params = ClooverRaffleTypes.CreateRaffleParams({
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
      ClooverRaffleTypes.CreateRaffleParams memory params = ClooverRaffleTypes.CreateRaffleParams({
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
      ClooverRaffleTypes.CreateRaffleParams memory params = ClooverRaffleTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20WithPermit,
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
      mockERC20WithPermit.approve(address(raffle), 100e6);
      raffle.purchaseTickets(2);
      utils.goForward(ticketSaleDuration + 1);
      assertFalse(raffle.raffleStatus() == ClooverRaffleTypes.RaffleStatus.DRAWN);
  
      address[] memory raffleContract = new address[](1);
      raffleContract[0] = address(raffle);
      factory.batchClooverRaffledraw(raffleContract);

      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffle));
      mockRamdomProvider.generateRandomNumbers(requestId);
      assertTrue(raffle.raffleStatus() == ClooverRaffleTypes.RaffleStatus.DRAWN);
   }
   
   function test_CorrectlyRequestRandomNumberForSeveralClooverRaffles() external {
      mockERC721.mint(alice, nftIdTwo);
      changePrank(alice);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC721.approve(address(factory), nftIdTwo);
      ClooverRaffleTypes.CreateRaffleParams memory params = ClooverRaffleTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20WithPermit,
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
      mockERC20WithPermit.approve(address(raffleOne), 100e6);
      raffleOne.purchaseTickets(2);
      mockERC20WithPermit.approve(address(raffleTwo), 100e6);
      raffleTwo.purchaseTickets(1);
      utils.goForward(ticketSaleDuration + 1);
      assertFalse(raffleOne.raffleStatus() == ClooverRaffleTypes.RaffleStatus.DRAWN);
      assertFalse(raffleTwo.raffleStatus() == ClooverRaffleTypes.RaffleStatus.DRAWN);
  
      address[] memory raffleContract = new address[](2);
      raffleContract[0] = address(raffleOne);
      raffleContract[1] = address(raffleTwo);
      factory.batchClooverRaffledraw(raffleContract);

      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffleOne));
      mockRamdomProvider.generateRandomNumbers(requestId);
      requestId = mockRamdomProvider.callerToRequestId(address(raffleTwo));
      mockRamdomProvider.generateRandomNumbers(requestId);
      assertTrue(raffleOne.raffleStatus() == ClooverRaffleTypes.RaffleStatus.DRAWN);
      assertTrue(raffleTwo.raffleStatus() == ClooverRaffleTypes.RaffleStatus.DRAWN);
   }

   function test_RevertIf_OneOfTheClooverRaffleHasAlreadyBeenDrawned() external {
      mockERC721.mint(alice, nftIdTwo);
      changePrank(alice);
      mockERC721.approve(address(factory), nftIdOne);
      mockERC721.approve(address(factory), nftIdTwo);

      ClooverRaffleTypes.CreateRaffleParams memory params = ClooverRaffleTypes.CreateRaffleParams({
         purchaseCurrency: mockERC20WithPermit,
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
      mockERC20WithPermit.approve(address(raffleOne), 100e6);
      raffleOne.purchaseTickets(10);
      mockERC20WithPermit.approve(address(raffleTwo), 100e6);
      raffleTwo.purchaseTickets(2);

      utils.goForward(ticketSaleDuration + 1);
      raffleOne.draw();
      uint256 requestId = mockRamdomProvider.callerToRequestId(address(raffleOne));
      mockRamdomProvider.generateRandomNumbers(requestId);
      raffleOne.winningTicket();
      assertTrue(raffleOne.raffleStatus() == ClooverRaffleTypes.RaffleStatus.DRAWN);
      assertFalse(raffleTwo.raffleStatus() == ClooverRaffleTypes.RaffleStatus.DRAWN);

      address[] memory raffleContract = new address[](2);
      raffleContract[0] = address(raffleOne);
      raffleContract[1] = address(raffleTwo);
      vm.expectRevert(Errors.TICKET_ALREADY_DRAWN.selector);
      factory.batchClooverRaffledraw(raffleContract);
   }

   function test_DeregisterClooverRaffle() external{
      changePrank(alice);
      ClooverRaffleTypes.CreateRaffleParams memory params = ClooverRaffleTypes.CreateRaffleParams({
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
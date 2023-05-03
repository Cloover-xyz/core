// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";

import {ClooverRaffle} from "../../../src/raffle/ClooverRaffle.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ClooverRaffleDataTypes} from "../../../src/libraries/types/ClooverRaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupClooverRaffles} from "./SetupClooverRaffles.sol";

contract InitializeClooverRaffleTest is Test, SetupClooverRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupClooverRaffles.setUp();
    }

    function test_Initialize_TokenRaffle() external{
        // Without insurance
        assertEq(tokenRaffle.creator(), alice);
        assertEq(tokenRaffle.ticketPrice(), ticketPrice);
        assertEq(tokenRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(tokenRaffle.currentSupply(), 0);
        assertEq(tokenRaffle.maxTotalSupply(), maxTotalSupply);
        assertFalse(tokenRaffle.isEthRaffle());
        assertEq(address(tokenRaffle.purchaseCurrency()), address(mockERC20));
        (IERC721 contractAddress, uint256 id )= tokenRaffle.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,tokenNftId);
        assertEq(contractAddress.ownerOf(tokenNftId) ,address(tokenRaffle));

        // With insurance
        uint256 insuranceCost = uint256(minTicketSalesInsurance).calculateInsuranceCost(ticketPrice, INSURANCE_RATE);
        assertEq(tokenRaffleWithInsurance.creator(), carole);
        assertEq(tokenRaffleWithInsurance.ticketPrice(), ticketPrice);
        assertEq(tokenRaffleWithInsurance.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(tokenRaffleWithInsurance.currentSupply(), 0);
        assertEq(tokenRaffleWithInsurance.maxTotalSupply(), maxTotalSupply);
        assertEq(tokenRaffleWithInsurance.insurancePaid(), insuranceCost);
        assertFalse(tokenRaffleWithInsurance.isEthRaffle());
        assertEq(address(tokenRaffleWithInsurance.purchaseCurrency()), address(mockERC20));
        (contractAddress, id )= tokenRaffleWithInsurance.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,tokenWithAssuranceNftId);
        assertEq(contractAddress.ownerOf(tokenWithAssuranceNftId) ,address(tokenRaffleWithInsurance));
    }

    function test_Initialize_TokenRaffle_RevertWhen_RaffleAlreadyInitialize() external{
        ClooverRaffleDataTypes.InitializeRaffleParams memory data = ClooverRaffleDataTypes
            .InitializeRaffleParams({
                creator:alice,
                implementationManager: implementationManager,
                purchaseCurrency: mockERC20,
                nftContract: mockERC721,
                nftId: tokenNftId,
                ticketPrice: ticketPrice,
                ticketSalesDuration: ticketSaleDuration,
                maxTotalSupply: maxTotalSupply,
                maxTicketAllowedToPurchase: 0,
                ticketSalesInsurance: 0,
                royaltiesRate: 0
        });
        vm.expectRevert("Initializable: contract is already initialized");
        tokenRaffle.initialize(data);
    }

    function test_Initialize_TokenRaffle_RevertWhen_ClooverRaffleDataNotCorrect() external{
        changePrank(alice);
        uint _nftId = 5;
        ClooverRaffle newClooverRaffle = new ClooverRaffle();
        mockERC721.mint(alice, _nftId);
        mockERC721.transferFrom(alice, address(newClooverRaffle), _nftId);
        //implementationManager == address(0)
        ClooverRaffleDataTypes.InitializeRaffleParams memory data = ClooverRaffleDataTypes
            .InitializeRaffleParams({
                creator:alice,
                implementationManager: ImplementationManager(address(0)),
                purchaseCurrency: mockERC20,
                nftContract: mockERC721,
                nftId: _nftId,
                ticketPrice: ticketPrice,
                ticketSalesDuration: ticketSaleDuration,
                maxTotalSupply: maxTotalSupply,
                maxTicketAllowedToPurchase: 0,
                ticketSalesInsurance: 0,
                royaltiesRate: 0
        });
        vm.expectRevert(Errors.NOT_ADDRESS_0.selector);
        newClooverRaffle.initialize(data);

        //Token not whitelisted
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: MockERC20(address(deployer)),
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.TOKEN_NOT_WHITELISTED.selector);
        newClooverRaffle.initialize(data);

        //NFT not whitelisted
        MockERC721 notWhitelistedCollection = new MockERC721("NOT WHITELISTED", "NFT");
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: mockERC20,
            nftContract: notWhitelistedCollection,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        newClooverRaffle.initialize(data);

        // ticketPrice == 0
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: mockERC20,
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: 0,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newClooverRaffle.initialize(data);

        // maxTotalSupply == 0
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: mockERC20,
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: 0,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newClooverRaffle.initialize(data);

        // maxTotalSupply > maxTotalSupplyAllowed
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: mockERC20,
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: MAX_TICKET_SUPPLY+1,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        newClooverRaffle.initialize(data);

        // ticketSaleDuration < minTicketSalesDuration
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: mockERC20,
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: uint64(MIN_SALE_DURATION) - 1,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newClooverRaffle.initialize(data);

        // ticketSaleDuration > maxTicketSalesDuration
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: mockERC20,
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: uint64(MAX_SALE_DURATION) + 1,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newClooverRaffle.initialize(data);

        //minTicketSalesInsurance > 0 && transfer value < insuranceCost
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: mockERC20,
            nftContract: mockERC721,
            nftId: _nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 1,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newClooverRaffle.initialize(data);
    }

    function test_Initialize_EthRaffle() external{
        // Without insurance
        assertEq(ethRaffle.creator(), alice);
        assertEq(ethRaffle.ticketPrice(), ticketPrice);
        assertEq(ethRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(ethRaffle.currentSupply(), 0);
        assertEq(ethRaffle.maxTotalSupply(), maxTotalSupply);
        assertTrue(ethRaffle.isEthRaffle());
        assertEq(address(ethRaffle.purchaseCurrency()), address(0));
        (IERC721 contractAddress, uint256 id )= ethRaffle.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,ethNftId);
        assertEq(contractAddress.ownerOf(ethNftId) ,address(ethRaffle));

        // With insurance
        uint256 insuranceCost = uint256(minTicketSalesInsurance).calculateInsuranceCost(ticketPrice, INSURANCE_RATE);
        assertEq(ethRaffleWithInsurance.creator(), carole);
        assertEq(ethRaffleWithInsurance.ticketPrice(), ticketPrice);
        assertEq(ethRaffleWithInsurance.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(ethRaffleWithInsurance.currentSupply(), 0);
        assertEq(ethRaffleWithInsurance.maxTotalSupply(), maxTotalSupply);
        assertEq(ethRaffleWithInsurance.insurancePaid(), insuranceCost);
        assertTrue(ethRaffleWithInsurance.isEthRaffle());
        assertEq(address(ethRaffleWithInsurance.purchaseCurrency()), address(0));
        (contractAddress, id )= ethRaffleWithInsurance.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,ethWithAssuranceNftId);
        assertEq(contractAddress.ownerOf(ethWithAssuranceNftId) ,address(ethRaffleWithInsurance));
    }
    
    function test_Initialize_EthRaffle_RevertWhen_RaffleAlreadyInitialize() external{
        ClooverRaffleDataTypes.InitializeRaffleParams memory  data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: ethNftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert("Initializable: contract is already initialized");
        ethRaffle.initialize(data);
    }

    function test_Initialize_EthRaffle_RevertWhen_ClooverRaffleDataNotCorrect() external{
        changePrank(alice);
        uint _nftId = 50;
        ClooverRaffle newClooverRaffle = new ClooverRaffle();
        mockERC721.mint(alice, _nftId);
        mockERC721.transferFrom(alice, address(newClooverRaffle), _nftId);
        //implementationManager == address(0)
        ClooverRaffleDataTypes.InitializeRaffleParams memory  data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: ImplementationManager(address(0)),
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: ethNftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.NOT_ADDRESS_0.selector);
        newClooverRaffle.initialize(data);

    
        //NFT not whitelisted
        MockERC721 notWhitelistedCollection = new MockERC721("NOT WHITELISTED", "NFT");
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: notWhitelistedCollection,
            nftId: ethNftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        newClooverRaffle.initialize(data);

        // ticketPrice == 0
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: ethNftId,
            ticketPrice: 0,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newClooverRaffle.initialize(data);

        // maxTotalSupply == 0
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: ethNftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: 0,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newClooverRaffle.initialize(data);

        // maxTotalSupply > maxTotalSupplyAllowed
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: ethNftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: MAX_TICKET_SUPPLY+1,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        newClooverRaffle.initialize(data);

        // ticketSaleDuration < minTicketSalesDuration
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: ethNftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: uint64(MIN_SALE_DURATION) - 1,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newClooverRaffle.initialize(data);

        // ticketSaleDuration > maxTicketSalesDuration
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: ethNftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: uint64(MAX_SALE_DURATION) + 1,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: 0,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newClooverRaffle.initialize(data);

        // msg.value != insuranceCost
        data = ClooverRaffleDataTypes.InitializeRaffleParams({
            creator:alice,
            implementationManager: implementationManager,
            purchaseCurrency: IERC20(address(0)),
            nftContract: mockERC721,
            nftId: ethNftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSaleDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: 0,
            ticketSalesInsurance: minTicketSalesInsurance,
            royaltiesRate: 0
        });
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newClooverRaffle.initialize(data);
    }
}
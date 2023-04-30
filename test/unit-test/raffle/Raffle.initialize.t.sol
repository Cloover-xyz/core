// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";

import {Raffle} from "../../../src/raffle/Raffle.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {RaffleDataTypes} from "../../../src/libraries/types/RaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupRaffles} from "./SetupRaffles.sol";

contract InitializeRaffleTest is Test, SetupRaffles {
    using InsuranceLogic for uint;

    function setUp() public virtual override {
        SetupRaffles.setUp();
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

    function test_Initialize_TokenRaffle_RevertWhen_RaffleAlreadyInitialize() external{
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

    function test_Initialize_TokenRaffle_RevertWhen_RaffleDataNotCorrect() external{
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

    function test_Initialize_EthRaffle() external{
        // Without insurance
        assertEq(ethRaffle.creator(), alice);
        assertEq(ethRaffle.ticketPrice(), ticketPrice);
        assertEq(ethRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(ethRaffle.totalSupply(), 0);
        assertEq(ethRaffle.maxSupply(), maxTicketSupply);
        assertTrue(ethRaffle.isEthTokenSales());
        assertEq(address(ethRaffle.purchaseCurrency()), address(0));
        (IERC721 contractAddress, uint256 id )= ethRaffle.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,ethNftId);
        assertEq(contractAddress.ownerOf(ethNftId) ,address(ethRaffle));

        // With insurance
        uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        assertEq(ethRaffleWithInsurance.creator(), carole);
        assertEq(ethRaffleWithInsurance.ticketPrice(), ticketPrice);
        assertEq(ethRaffleWithInsurance.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(ethRaffleWithInsurance.totalSupply(), 0);
        assertEq(ethRaffleWithInsurance.maxSupply(), maxTicketSupply);
        assertEq(ethRaffleWithInsurance.insurancePaid(), insuranceCost);
        assertTrue(ethRaffleWithInsurance.isEthTokenSales());
        assertEq(address(ethRaffleWithInsurance.purchaseCurrency()), address(0));
        (contractAddress, id )= ethRaffleWithInsurance.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,ethWithAssuranceNftId);
        assertEq(contractAddress.ownerOf(ethWithAssuranceNftId) ,address(ethRaffleWithInsurance));
    }
    
    function test_Initialize_EthRaffle_RevertWhen_RaffleAlreadyInitialize() external{
        RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            ethNftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            true,
            0
        );
        vm.expectRevert("Initializable: contract is already initialized");
        ethRaffle.initialize(data);
    }

    function test_Initialize_EthRaffle_RevertWhen_RaffleDataNotCorrect() external{
        changePrank(alice);
        uint _nftId = 3;
        Raffle newRaffle = new Raffle();
        mockERC721.mint(alice, _nftId);
        mockERC721.transferFrom(alice, address(newRaffle), _nftId);
        //implementationManager == address(0)
        RaffleDataTypes.InitRaffleParams memory data = RaffleDataTypes.InitRaffleParams(
            ImplementationManager(address(0)),
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            true,
            0
        );
        vm.expectRevert(Errors.NOT_ADDRESS_0.selector);
        newRaffle.initialize(data);

    
        //NFT not whitelisted
        MockERC721 notWhitelistedCollection = new MockERC721("NOT WHITELISTED", "NFT");
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            notWhitelistedCollection,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            ticketSaleDuration,
            true,
            0
        );
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        newRaffle.initialize(data);

        // ticketPrice == 0
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            0,
            0,
            ticketSaleDuration,
            true,
            0
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newRaffle.initialize(data);

        // maxTicketSupply == 0
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            0,
            ticketPrice,
            0,
            ticketSaleDuration,
            true,
            0
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newRaffle.initialize(data);

        // maxTicketSupply > maxTicketSupplyAllowed
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            MAX_TICKET_SUPPLY+1,
            ticketPrice,
            0,
            ticketSaleDuration,
            true,
            0
        );
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        newRaffle.initialize(data);

        // ticketSaleDuration < minTicketSalesDuration
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            uint64(MIN_SALE_DURATION) - 1,
            true,
            0
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newRaffle.initialize(data);

        // ticketSaleDuration > maxTicketSalesDuration
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            0,
            uint64(MAX_SALE_DURATION) + 1,
            true,
            0
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newRaffle.initialize(data);

        // msg.value != insuranceCost
        data = RaffleDataTypes.InitRaffleParams(
            implementationManager,
            IERC20(address(0)),
            mockERC721,
            alice,
            _nftId,
            maxTicketSupply,
            ticketPrice,
            minTicketSalesInsurance,
            ticketSaleDuration,
            true,
            0
        );
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newRaffle.initialize(data);
    }
}
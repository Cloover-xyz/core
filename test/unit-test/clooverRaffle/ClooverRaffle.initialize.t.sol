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

    function test_Initialize_TokenClooverRaffle() external{
        // Without insurance
        assertEq(tokenClooverRaffle.creator(), alice);
        assertEq(tokenClooverRaffle.ticketPrice(), ticketPrice);
        assertEq(tokenClooverRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(tokenClooverRaffle.totalSupply(), 0);
        assertEq(tokenClooverRaffle.maxSupply(), maxTicketSupply);
        assertFalse(tokenClooverRaffle.isEthTokenSales());
        assertEq(address(tokenClooverRaffle.purchaseCurrency()), address(mockERC20));
        (IERC721 contractAddress, uint256 id )= tokenClooverRaffle.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,tokenNftId);
        assertEq(contractAddress.ownerOf(tokenNftId) ,address(tokenClooverRaffle));

        // With insurance
        uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        assertEq(tokenClooverRaffleWithInsurance.creator(), carole);
        assertEq(tokenClooverRaffleWithInsurance.ticketPrice(), ticketPrice);
        assertEq(tokenClooverRaffleWithInsurance.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(tokenClooverRaffleWithInsurance.totalSupply(), 0);
        assertEq(tokenClooverRaffleWithInsurance.maxSupply(), maxTicketSupply);
        assertEq(tokenClooverRaffleWithInsurance.insurancePaid(), insuranceCost);
        assertFalse(tokenClooverRaffleWithInsurance.isEthTokenSales());
        assertEq(address(tokenClooverRaffleWithInsurance.purchaseCurrency()), address(mockERC20));
        (contractAddress, id )= tokenClooverRaffleWithInsurance.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,tokenWithAssuranceNftId);
        assertEq(contractAddress.ownerOf(tokenWithAssuranceNftId) ,address(tokenClooverRaffleWithInsurance));
    }

    function test_Initialize_TokenClooverRaffle_RevertWhen_ClooverRaffleAlreadyInitialize() external{
        ClooverRaffleDataTypes.InitClooverRaffleParams memory data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert("Initializable: contract is already initialized");
        tokenClooverRaffle.initialize(data);
    }

    function test_Initialize_TokenClooverRaffle_RevertWhen_ClooverRaffleDataNotCorrect() external{
        changePrank(alice);
        uint _nftId = 5;
        ClooverRaffle newClooverRaffle = new ClooverRaffle();
        mockERC721.mint(alice, _nftId);
        mockERC721.transferFrom(alice, address(newClooverRaffle), _nftId);
        //implementationManager == address(0)
        ClooverRaffleDataTypes.InitClooverRaffleParams memory data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.NOT_ADDRESS_0.selector);
        newClooverRaffle.initialize(data);

        //Token not whitelisted
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.TOKEN_NOT_WHITELISTED.selector);
        newClooverRaffle.initialize(data);

        //NFT not whitelisted
        MockERC721 notWhitelistedCollection = new MockERC721("NOT WHITELISTED", "NFT");
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        newClooverRaffle.initialize(data);

        // ticketPrice == 0
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newClooverRaffle.initialize(data);

        // maxTicketSupply == 0
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newClooverRaffle.initialize(data);

        // maxTicketSupply > maxTicketSupplyAllowed
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        newClooverRaffle.initialize(data);

        // ticketSaleDuration < minTicketSalesDuration
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newClooverRaffle.initialize(data);

        // ticketSaleDuration > maxTicketSalesDuration
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newClooverRaffle.initialize(data);

        //minTicketSalesInsurance > 0 && transfer value == insuranceCost
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newClooverRaffle.initialize(data);
    }

    function test_Initialize_EthClooverRaffle() external{
        // Without insurance
        assertEq(ethClooverRaffle.creator(), alice);
        assertEq(ethClooverRaffle.ticketPrice(), ticketPrice);
        assertEq(ethClooverRaffle.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(ethClooverRaffle.totalSupply(), 0);
        assertEq(ethClooverRaffle.maxSupply(), maxTicketSupply);
        assertTrue(ethClooverRaffle.isEthTokenSales());
        assertEq(address(ethClooverRaffle.purchaseCurrency()), address(0));
        (IERC721 contractAddress, uint256 id )= ethClooverRaffle.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,ethNftId);
        assertEq(contractAddress.ownerOf(ethNftId) ,address(ethClooverRaffle));

        // With insurance
        uint256 insuranceCost = minTicketSalesInsurance.calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        assertEq(ethClooverRaffleWithInsurance.creator(), carole);
        assertEq(ethClooverRaffleWithInsurance.ticketPrice(), ticketPrice);
        assertEq(ethClooverRaffleWithInsurance.endTicketSales(), uint64(block.timestamp) + ticketSaleDuration);
        assertEq(ethClooverRaffleWithInsurance.totalSupply(), 0);
        assertEq(ethClooverRaffleWithInsurance.maxSupply(), maxTicketSupply);
        assertEq(ethClooverRaffleWithInsurance.insurancePaid(), insuranceCost);
        assertTrue(ethClooverRaffleWithInsurance.isEthTokenSales());
        assertEq(address(ethClooverRaffleWithInsurance.purchaseCurrency()), address(0));
        (contractAddress, id )= ethClooverRaffleWithInsurance.nftToWin();
        assertEq(address(contractAddress) ,address(mockERC721));
        assertEq(id ,ethWithAssuranceNftId);
        assertEq(contractAddress.ownerOf(ethWithAssuranceNftId) ,address(ethClooverRaffleWithInsurance));
    }
    
    function test_Initialize_EthClooverRaffle_RevertWhen_ClooverRaffleAlreadyInitialize() external{
        ClooverRaffleDataTypes.InitClooverRaffleParams memory data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert("Initializable: contract is already initialized");
        ethClooverRaffle.initialize(data);
    }

    function test_Initialize_EthClooverRaffle_RevertWhen_ClooverRaffleDataNotCorrect() external{
        changePrank(alice);
        uint _nftId = 50;
        ClooverRaffle newClooverRaffle = new ClooverRaffle();
        mockERC721.mint(alice, _nftId);
        mockERC721.transferFrom(alice, address(newClooverRaffle), _nftId);
        //implementationManager == address(0)
        ClooverRaffleDataTypes.InitClooverRaffleParams memory data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.NOT_ADDRESS_0.selector);
        newClooverRaffle.initialize(data);

    
        //NFT not whitelisted
        MockERC721 notWhitelistedCollection = new MockERC721("NOT WHITELISTED", "NFT");
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        newClooverRaffle.initialize(data);

        // ticketPrice == 0
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newClooverRaffle.initialize(data);

        // maxTicketSupply == 0
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        newClooverRaffle.initialize(data);

        // maxTicketSupply > maxTicketSupplyAllowed
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        newClooverRaffle.initialize(data);

        // ticketSaleDuration < minTicketSalesDuration
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newClooverRaffle.initialize(data);

        // ticketSaleDuration > maxTicketSalesDuration
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        newClooverRaffle.initialize(data);

        // msg.value != insuranceCost
        data = ClooverRaffleDataTypes.InitClooverRaffleParams(
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
            0,
            0
        );
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        newClooverRaffle.initialize(data);
    }
}
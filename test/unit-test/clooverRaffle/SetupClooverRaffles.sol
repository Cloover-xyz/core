// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";
import {MockRandomProvider} from "../../../src/mocks/MockRandomProvider.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {NFTCollectionWhitelist} from "../../../src/core/NFTCollectionWhitelist.sol";
import {TokenWhitelist} from "../../../src/core/TokenWhitelist.sol";
import {ConfigManager} from "../../../src/core/ConfigManager.sol";
import {ClooverRaffleFactory} from "../../../src/raffle/ClooverRaffleFactory.sol";
import {ClooverRaffle} from "../../../src/raffle/ClooverRaffle.sol";

import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";
import {ConfigManagerDataTypes} from "../../../src/libraries/types/ConfigManagerDataTypes.sol";
import {ClooverRaffleDataTypes} from "../../../src/libraries/types/ClooverRaffleDataTypes.sol";
import {InsuranceLogic} from "../../../src/libraries/math/InsuranceLogic.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

contract SetupClooverRaffles is Test, SetupUsers {
    using InsuranceLogic for uint;

    MockERC20 mockERC20;
    MockERC721 mockERC721;
    MockRandomProvider mockRamdomProvider;

    ConfigManager configManager;
    ClooverRaffleFactory raffleFactory;
    ImplementationManager implementationManager;
    NFTCollectionWhitelist nftCollectionWhitelist;
    TokenWhitelist tokenWhitelist;
    AccessController accessController;

    ClooverRaffle tokenRaffle;
    ClooverRaffle tokenRaffleWithInsurance;
    ClooverRaffle tokenRaffleWithRoyalties;
    ClooverRaffle ethRaffle;
    ClooverRaffle ethRaffleWithInsurance;
    ClooverRaffle ethRaffleWithRoyalties;

    uint256 ticketPrice = 2e18; // 10
    uint64 ticketSaleDuration = 1 days;
    uint16 maxTotalSupply = 10;
    uint16 minTicketSalesInsurance = 5;
    uint16 royaltiesRate = 2.5e2; //2.5%

    uint256 tokenNftId = 1;
    uint256 tokenWithAssuranceNftId = 2;
    uint256 tokenWithRoyaltiesNftId = 3;
    uint256 ethNftId = 11;
    uint256 ethWithAssuranceNftId = 12;
    uint256 ethWithRoyaltiesNftId = 13;

    uint256 tokenRaffleInsuranceCost;
    uint256 ethRaffleInsuranceCost;

    uint64 MIN_SALE_DURATION = 1 days;
    uint64 MAX_SALE_DURATION = 2 weeks;
    uint16 MAX_TICKET_SUPPLY = 10000;
    uint16 PROTOCOL_FEE_RATE = 1e2; // 1%
    uint16 INSURANCE_RATE = 2.5e2; //2.5%

    constructor() {
        SetupUsers.setUp();

        vm.startPrank(deployer);

        mockERC20 = new MockERC20("Mocked Test", "Test", 18);
        mockERC20.mint(bob, 100e18);
        mockERC20.mint(carole, 100e18);

        mockERC721 = new MockERC721("Mocked NFT", "NFT");

        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(
            address(accessController)
        );
        raffleFactory = new ClooverRaffleFactory(implementationManager);
        nftCollectionWhitelist = new NFTCollectionWhitelist(
            implementationManager
        );
        tokenWhitelist = new TokenWhitelist(implementationManager);

        ConfigManagerDataTypes.InitConfigManagerParams memory configData = ConfigManagerDataTypes.InitConfigManagerParams(
            MAX_TICKET_SUPPLY,
            PROTOCOL_FEE_RATE,
            INSURANCE_RATE,
            MIN_SALE_DURATION,
            MAX_SALE_DURATION
        );
        configManager = new ConfigManager(implementationManager, configData);
        mockRamdomProvider = new MockRandomProvider(implementationManager);

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.ClooverRaffleFactory,
            address(raffleFactory)
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
            treasury
        );

        nftCollectionWhitelist.addToWhitelist(address(mockERC721), admin);
        tokenWhitelist.addToWhitelist(address(mockERC20));
    }

    function setUp() public virtual override {
        mockERC721.mint(alice, tokenNftId);
        mockERC721.mint(alice, ethNftId);
        mockERC721.mint(carole, tokenWithAssuranceNftId);
        mockERC721.mint(carole, ethWithAssuranceNftId);
        mockERC721.mint(alice, tokenWithRoyaltiesNftId);
        mockERC721.mint(alice, ethWithRoyaltiesNftId);

        changePrank(alice);
        tokenRaffle = new ClooverRaffle();
        ClooverRaffleDataTypes.InitializeRaffleParams memory raffleData = ClooverRaffleDataTypes
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
        mockERC721.transferFrom(alice, address(tokenRaffle), tokenNftId);
        tokenRaffle.initialize(raffleData);

        ethRaffle = new ClooverRaffle();
        ClooverRaffleDataTypes.InitializeRaffleParams memory ethRaffleData = ClooverRaffleDataTypes
            .InitializeRaffleParams({
                creator: alice,
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
        mockERC721.transferFrom(alice, address(ethRaffle), ethNftId);
        ethRaffle.initialize(ethRaffleData);

        tokenRaffleWithRoyalties = new ClooverRaffle();
         ClooverRaffleDataTypes.InitializeRaffleParams memory raffleWithRoyaltiesData = ClooverRaffleDataTypes
            .InitializeRaffleParams({
                creator: alice,
                implementationManager: implementationManager,
                purchaseCurrency: mockERC20,
                nftContract: mockERC721,
                nftId: tokenWithRoyaltiesNftId,
                ticketPrice: ticketPrice,
                ticketSalesDuration: ticketSaleDuration,
                maxTotalSupply: maxTotalSupply,
                maxTicketAllowedToPurchase: 0,
                ticketSalesInsurance: 0,
                royaltiesRate: royaltiesRate
        });

        mockERC721.transferFrom(alice, address(tokenRaffleWithRoyalties), tokenWithRoyaltiesNftId);
        tokenRaffleWithRoyalties.initialize(raffleWithRoyaltiesData);

        ethRaffleWithRoyalties = new ClooverRaffle();
        ClooverRaffleDataTypes.InitializeRaffleParams memory ethRaffleWithRoyaltiesData = ClooverRaffleDataTypes
            .InitializeRaffleParams({
                creator: alice,
                implementationManager: implementationManager,
                purchaseCurrency: IERC20(address(0)),
                nftContract: mockERC721,
                nftId: ethWithRoyaltiesNftId,
                ticketPrice: ticketPrice,
                ticketSalesDuration: ticketSaleDuration,
                maxTotalSupply: maxTotalSupply,
                maxTicketAllowedToPurchase: 0,
                ticketSalesInsurance: 0,
                royaltiesRate: royaltiesRate
        });

        mockERC721.transferFrom(alice, address(ethRaffleWithRoyalties), ethWithRoyaltiesNftId);
        ethRaffleWithRoyalties.initialize(ethRaffleWithRoyaltiesData);

        changePrank(carole);
        tokenRaffleWithInsurance = new ClooverRaffle();
        ClooverRaffleDataTypes.InitializeRaffleParams memory tokenRaffleWithInsuranceData = ClooverRaffleDataTypes
            .InitializeRaffleParams({
                creator: carole,
                implementationManager: implementationManager,
                purchaseCurrency: mockERC20,
                nftContract: mockERC721,
                nftId: tokenWithAssuranceNftId,
                ticketPrice: ticketPrice,
                ticketSalesDuration: ticketSaleDuration,
                maxTotalSupply: maxTotalSupply,
                maxTicketAllowedToPurchase: 0,
                ticketSalesInsurance: minTicketSalesInsurance,
                royaltiesRate: 0
        });
        mockERC721.transferFrom(
            carole,
            address(tokenRaffleWithInsurance),
            tokenWithAssuranceNftId
        );
        tokenRaffleInsuranceCost = uint256(minTicketSalesInsurance)
            .calculateInsuranceCost(ticketPrice, INSURANCE_RATE);
        mockERC20.transfer(
            address(tokenRaffleWithInsurance),
            tokenRaffleInsuranceCost
        );
        tokenRaffleWithInsurance.initialize(tokenRaffleWithInsuranceData);

        ethRaffleWithInsurance = new ClooverRaffle();
        ClooverRaffleDataTypes.InitializeRaffleParams memory ethRaffleWithInsuranceData = ClooverRaffleDataTypes
            .InitializeRaffleParams({
                creator: carole,
                implementationManager: implementationManager,
                purchaseCurrency: IERC20(address(0)),
                nftContract: mockERC721,
                nftId: ethWithAssuranceNftId,
                ticketPrice: ticketPrice,
                ticketSalesDuration: ticketSaleDuration,
                maxTotalSupply: maxTotalSupply,
                maxTicketAllowedToPurchase: 0,
                ticketSalesInsurance: minTicketSalesInsurance,
                royaltiesRate: 0
        });
        mockERC721.transferFrom(
            carole,
            address(ethRaffleWithInsurance),
            ethWithAssuranceNftId
        );
        ethRaffleInsuranceCost = uint256(minTicketSalesInsurance).calculateInsuranceCost(
            ticketPrice,
            INSURANCE_RATE
        );
        ethRaffleWithInsurance.initialize{value: ethRaffleInsuranceCost}(
            ethRaffleWithInsuranceData
        );
    }
}

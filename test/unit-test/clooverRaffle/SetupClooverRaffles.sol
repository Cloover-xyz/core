// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

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
import {ConfiguratorInputTypes} from "../../../src/libraries/types/ConfiguratorInputTypes.sol";
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

    ClooverRaffle tokenClooverRaffle;
    ClooverRaffle tokenClooverRaffleWithInsurance;
    ClooverRaffle tokenClooverRaffleWithRoyalties;
    ClooverRaffle ethClooverRaffle;
    ClooverRaffle ethClooverRaffleWithInsurance;
    ClooverRaffle ethClooverRaffleWithRoyalties;

    uint256 maxTicketSupply = 10;
    uint256 ticketPrice = 2e18; // 10
    uint256 minTicketSalesInsurance = 5;
    uint64 ticketSaleDuration = 1 days;
    uint256 royaltiesPercentage = 2.5e2; //2.5%

    uint256 tokenNftId = 1;
    uint256 tokenWithAssuranceNftId = 2;
    uint256 tokenWithRoyaltiesNftId = 3;
    uint256 ethNftId = 11;
    uint256 ethWithAssuranceNftId = 12;
    uint256 ethWithRoyaltiesNftId = 13;

    uint256 tokenClooverRaffleInsuranceCost;
    uint256 ethClooverRaffleInsuranceCost;

    uint256 MIN_SALE_DURATION = 1 days;
    uint256 MAX_SALE_DURATION = 2 weeks;
    uint256 MAX_TICKET_SUPPLY = 10000;
    uint256 PROTOCOL_FEES_PERCENTAGE = 1e2; // 1%
    uint256 INSURANCE_SALES_PERCENTAGE = 2.5e2; //2.5%

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

        ConfiguratorInputTypes.InitConfigManagerInput
            memory configData = ConfiguratorInputTypes.InitConfigManagerInput(
                PROTOCOL_FEES_PERCENTAGE,
                MAX_TICKET_SUPPLY,
                MIN_SALE_DURATION,
                MAX_SALE_DURATION,
                INSURANCE_SALES_PERCENTAGE
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
        tokenClooverRaffle = new ClooverRaffle();
        ClooverRaffleDataTypes.InitClooverRaffleParams memory raffleData = ClooverRaffleDataTypes
            .InitClooverRaffleParams(
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
        mockERC721.transferFrom(alice, address(tokenClooverRaffle), tokenNftId);
        tokenClooverRaffle.initialize(raffleData);

        ethClooverRaffle = new ClooverRaffle();
        ClooverRaffleDataTypes.InitClooverRaffleParams memory ethClooverRaffleData = ClooverRaffleDataTypes
            .InitClooverRaffleParams(
                implementationManager,
                mockERC20,
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
        mockERC721.transferFrom(alice, address(ethClooverRaffle), ethNftId);
        ethClooverRaffle.initialize(ethClooverRaffleData);

        tokenClooverRaffleWithRoyalties = new ClooverRaffle();
        ClooverRaffleDataTypes.InitClooverRaffleParams memory raffleWithRoyaltiesData = ClooverRaffleDataTypes
            .InitClooverRaffleParams(
                implementationManager,
                mockERC20,
                mockERC721,
                alice,
                tokenWithRoyaltiesNftId,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                false,
                0,
                royaltiesPercentage
            );
        mockERC721.transferFrom(alice, address(tokenClooverRaffleWithRoyalties), tokenWithRoyaltiesNftId);
        tokenClooverRaffleWithRoyalties.initialize(raffleWithRoyaltiesData);

        ethClooverRaffleWithRoyalties = new ClooverRaffle();
        ClooverRaffleDataTypes.InitClooverRaffleParams memory ethClooverRaffleWithRoyaltiesData = ClooverRaffleDataTypes
            .InitClooverRaffleParams(
                implementationManager,
                mockERC20,
                mockERC721,
                alice,
                ethWithRoyaltiesNftId,
                maxTicketSupply,
                ticketPrice,
                0,
                ticketSaleDuration,
                true,
                0,
                royaltiesPercentage
            );
        mockERC721.transferFrom(alice, address(ethClooverRaffleWithRoyalties), ethWithRoyaltiesNftId);
        ethClooverRaffleWithRoyalties.initialize(ethClooverRaffleWithRoyaltiesData);

        changePrank(carole);
        tokenClooverRaffleWithInsurance = new ClooverRaffle();
        ClooverRaffleDataTypes.InitClooverRaffleParams
            memory tokenClooverRaffleWithInsuranceData = ClooverRaffleDataTypes
                .InitClooverRaffleParams(
                    implementationManager,
                    mockERC20,
                    mockERC721,
                    carole,
                    tokenWithAssuranceNftId,
                    maxTicketSupply,
                    ticketPrice,
                    minTicketSalesInsurance,
                    ticketSaleDuration,
                    false,
                    0,
                    0
                );
        mockERC721.transferFrom(
            carole,
            address(tokenClooverRaffleWithInsurance),
            tokenWithAssuranceNftId
        );
        tokenClooverRaffleInsuranceCost = minTicketSalesInsurance
            .calculateInsuranceCost(ticketPrice, INSURANCE_SALES_PERCENTAGE);
        mockERC20.transfer(
            address(tokenClooverRaffleWithInsurance),
            tokenClooverRaffleInsuranceCost
        );
        tokenClooverRaffleWithInsurance.initialize(tokenClooverRaffleWithInsuranceData);

        ethClooverRaffleWithInsurance = new ClooverRaffle();
        ClooverRaffleDataTypes.InitClooverRaffleParams
            memory ethClooverRaffleWithInsuranceData = ClooverRaffleDataTypes
                .InitClooverRaffleParams(
                    implementationManager,
                    mockERC20,
                    mockERC721,
                    carole,
                    ethWithAssuranceNftId,
                    maxTicketSupply,
                    ticketPrice,
                    minTicketSalesInsurance,
                    ticketSaleDuration,
                    true,
                    0,
                    0
                );
        mockERC721.transferFrom(
            carole,
            address(ethClooverRaffleWithInsurance),
            ethWithAssuranceNftId
        );
        ethClooverRaffleInsuranceCost = minTicketSalesInsurance.calculateInsuranceCost(
            ticketPrice,
            INSURANCE_SALES_PERCENTAGE
        );
        ethClooverRaffleWithInsurance.initialize{value: ethClooverRaffleInsuranceCost}(
            ethClooverRaffleWithInsuranceData
        );
    }
}

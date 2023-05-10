// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC20WithPermitMock} from "test/mocks/ERC20WithPermitMock.sol";
import {ERC721Mock} from "test/mocks/ERC721Mock.sol";
import {RandomProviderMock} from "test/mocks/RandomProviderMock.sol";

import {AccessController} from "src/core/AccessController.sol";
import {ImplementationManager} from "src/core/ImplementationManager.sol";
import {NFTWhitelist} from "src/core/NFTWhitelist.sol";
import {TokenWhitelist} from "src/core/TokenWhitelist.sol";

import {IClooverRaffleFactory} from "src/interfaces/IClooverRaffleFactory.sol";
import {ClooverRaffleFactory} from "src/raffleFactory/ClooverRaffleFactory.sol";
import {ClooverRaffle} from "src/raffle/ClooverRaffle.sol";

import {ClooverRaffleTypes} from "src/libraries/ClooverRaffleTypes.sol";
import {Errors} from "src/libraries/Errors.sol";

import "./BaseTest.sol";

contract IntegrationTest is BaseTest {

    AccessController internal accessController;
    ImplementationManager internal implementationManager;
    RandomProviderMock internal randomProviderMock;
    NFTWhitelist internal nftWhitelist;
    TokenWhitelist internal tokenWhitelist;

    ERC20WithPermitMock  internal erc20WithPermitMock;
    ERC721Mock internal erc721Mock;

    ClooverRaffleFactory factory;

    uint64 constant MIN_SALE_DURATION = 1 days;
    uint64 constant MAX_SALE_DURATION = 2 weeks;
    uint16 constant MAX_TICKET_SUPPLY = 10000;
    uint16 constant PROTOCOL_FEE_RATE = 1e2;
    uint16 constant INSURANCE_RATE = 5e2; //5%

    function setUp() public override {
        super.setUp();
        
        _deployCore();
        
        _deployFactory();

        _mockERC20();
        _mockERC721();
    }

    function _deployCore() internal {
        vm.startPrank(address(deployer));
        accessController = new AccessController(address(maintainer));
        implementationManager = new ImplementationManager(address(accessController));
        randomProviderMock = new RandomProviderMock(implementationManager);
        nftWhitelist = new NFTWhitelist(implementationManager);
        tokenWhitelist = new TokenWhitelist(implementationManager);

        changePrank(address(maintainer));
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.NFTWhitelist,
            address(nftWhitelist)
        );
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.TokenWhitelist,
            address(tokenWhitelist)
        );
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.RandomProvider,
            address(randomProviderMock)
        );
    }

    function _mockERC20() internal{
        erc20WithPermitMock = new ERC20WithPermitMock("Mocked USDC", "USDC", 6);
        changePrank(address(maintainer));
        tokenWhitelist.addToWhitelist(address(erc20WithPermitMock));
    }

    function _mockERC721() internal{
        erc721Mock = new ERC721Mock("Mocked NFT", "NFT");
        changePrank(address(maintainer));
        nftWhitelist.addToWhitelist(address(erc721Mock), address(collectionCreator));
    }

    function _deployFactory() internal{
        changePrank(address(maintainer));
            ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY,
            PROTOCOL_FEE_RATE,
            INSURANCE_RATE,
            MIN_SALE_DURATION,
            MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(implementationManager,configData);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.ClooverRaffleFactory,
            address(factory)
        );
        
    }

    function _mintERC20(address user, uint256 nftId) internal{
        erc721Mock.mint(user, nftId);
    }

    function _mintNFT(address user, uint256 nftId) internal{
        erc721Mock.mint(user, nftId);
    }

    function _boundPercentage(uint16 rate)
        internal
        view
        returns (uint16)
    {
        return uint16(bound(rate, 0, PercentageMath.PERCENTAGE_FACTOR));
    }

    function _boundPercentageExceed(uint16 rate)
        internal
        view
        returns (uint16)
    {
        return uint16(bound(rate, PercentageMath.PERCENTAGE_FACTOR, type(uint16).max));
    }


    function _boundMinSaleDuration(uint64 duration)
        internal
        view
        returns (uint64)
    {
        return uint64(bound(duration, 0, factory.maxTicketSalesDuration()));
    }

    function _boundMinSaleDurationExceedMax(uint64 duration)
        internal
        view
        returns (uint64)
    {
        return uint64(bound(duration, factory.maxTicketSalesDuration(), type(uint64).max));
    }

    function _boundMaxSaleDuration(uint64 duration)
        internal
        view
        returns (uint64)
    {
        return uint64(bound(duration, factory.minTicketSalesDuration(), 0));
    }

    function _boundMaxSaleDurationUnderMin(uint64 duration)
        internal
        view
        returns (uint64)
    {
        return uint64(bound(duration, 0, factory.minTicketSalesDuration()));
    }

    function _assumeNotExistingInterface(bytes32 interfaceName) pure internal {
        vm.assume(interfaceName != ImplementationInterfaceNames.AccessController);
        vm.assume(interfaceName != ImplementationInterfaceNames.RandomProvider);
        vm.assume(interfaceName != ImplementationInterfaceNames.NFTWhitelist);
        vm.assume(interfaceName != ImplementationInterfaceNames.TokenWhitelist);
        vm.assume(interfaceName != ImplementationInterfaceNames.ClooverRaffleFactory);
        vm.assume(interfaceName != ImplementationInterfaceNames.Treasury);
    }
}
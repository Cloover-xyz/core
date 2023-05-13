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

import {InsuranceLib} from "src/libraries/InsuranceLib.sol";
import {ClooverRaffleTypes} from "src/libraries/ClooverRaffleTypes.sol";
import {Errors} from "src/libraries/Errors.sol";
import {ClooverRaffleEvents, ClooverRaffleFactoryEvents} from "src/libraries/Events.sol";

import "./BaseTest.sol";
import "./SigUtils.sol";

contract IntegrationTest is BaseTest {
    SigUtils internal sigUtils;

    AccessController internal accessController;
    ImplementationManager internal implementationManager;
    RandomProviderMock internal randomProviderMock;
    NFTWhitelist internal nftWhitelist;
    TokenWhitelist internal tokenWhitelist;

    ERC721Mock erc721Mock;
    ERC20WithPermitMock erc20Mock;

    ClooverRaffleFactory factory;

    uint64 constant MIN_SALE_DURATION = 1 days;
    uint64 constant MAX_SALE_DURATION = 2 weeks;
    uint16 constant MAX_TICKET_SUPPLY = 10000;
    uint16 constant PROTOCOL_FEE_RATE = 2.5e2; // 2.5%
    uint16 constant INSURANCE_RATE = 5e2; //5%

    uint256 constant MIN_TICKET_PRICE = 10000;
    uint256 constant INITIAL_BALANCE = 10_000 ether;

    uint256 internal constant deployer_privateKey = 1;
    address internal deployer;
    uint256 internal constant treasury_privateKey = 2;
    address internal treasury;
    uint256 internal constant maintainer_privateKey = 3;
    address internal maintainer;
    uint256 internal constant collectionCreator_privateKey = 4;
    address internal collectionCreator;
    uint256 internal constant creator_privateKey = 5;
    address internal creator;
    uint256 internal constant participant1_privateKey = 6;
    address internal participant1;
    uint256 internal constant participant2_privateKey = 7;
    address internal participant2;

    function setUp() public virtual {
        _initWallets();
        _deploy();
    }

    function _initWallets() internal {
        deployer = _initUser(deployer_privateKey, 0);
        treasury = _initUser(treasury_privateKey, 0);
        maintainer = _initUser(maintainer_privateKey, 0);
        collectionCreator = _initUser(collectionCreator_privateKey, 0);
        creator = _initUser(creator_privateKey, INITIAL_BALANCE);
        participant1 = _initUser(participant1_privateKey, INITIAL_BALANCE);
        participant2 = _initUser(participant2_privateKey, INITIAL_BALANCE);

        _label();
    }

    function _label() internal {
        vm.label(deployer, "Deployer");
        vm.label(treasury, "Treasury");
        vm.label(maintainer, "Maintainer");
        vm.label(collectionCreator, "CollectionCreator");
        vm.label(creator, "Creator");
        vm.label(participant1, "Participant1");
        vm.label(participant2, "Participant2");
    }

    function _setEthBalances(address user, uint256 balance) internal {
        vm.deal(user, balance);
    }

    function _setERC20Balances(address token, address user, uint256 balance) internal {
        deal(token, user, balance / (10 ** (18 - ERC20(token).decimals())));
    }

    function _deploy() internal {
        vm.startPrank(deployer);
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));
        nftWhitelist = new NFTWhitelist(address(implementationManager));
        tokenWhitelist = new TokenWhitelist(address(implementationManager));
        randomProviderMock = new RandomProviderMock(address(implementationManager));

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(ImplementationInterfaceNames.Treasury, treasury);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.NFTWhitelist, address(nftWhitelist)
        );
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.TokenWhitelist, address(tokenWhitelist)
        );
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.RandomProvider, address(randomProviderMock)
        );

        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY, PROTOCOL_FEE_RATE, INSURANCE_RATE, MIN_SALE_DURATION, MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(address(implementationManager),configData);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.ClooverRaffleFactory, address(factory)
        );
    }

    function _initUser(uint256 privateKey, uint256 initialBalance) internal returns (address newUser) {
        newUser = vm.addr(privateKey);
        _setEthBalances(newUser, initialBalance);
    }

    function _mockERC20(uint8 decimals) internal returns (ERC20WithPermitMock erc20WithPermitMock) {
        erc20WithPermitMock = new ERC20WithPermitMock("Mock Token", "MT", decimals);
        changePrank(maintainer);
        tokenWhitelist.addToWhitelist(address(erc20WithPermitMock));
    }

    function _mintERC20(ERC20WithPermitMock erc20WithPermitMock, address to, uint256 amount) internal {
        erc20WithPermitMock.mint(to, amount);
    }

    function _mockERC721(address user) internal returns (ERC721Mock erc721) {
        erc721 = new ERC721Mock("Mock NFT", "MNFT");
        changePrank(maintainer);
        nftWhitelist.addToWhitelist(address(erc721), user);
    }

    function _mintERC721(ERC721Mock erc721, address to, uint256 nftId) internal {
        erc721.mint(to, nftId);
    }

    function _boundEthAmount(uint256 amount) internal view virtual returns (uint256) {
        return bound(amount, 1, INITIAL_BALANCE);
    }

    function _boundTicketPrice(uint256 ticketPrice) internal view returns (uint256) {
        return bound(ticketPrice, MIN_TICKET_PRICE, MAX_AMOUNT);
    }

    function _boundDuration(uint64 duration) internal view returns (uint64) {
        return uint64(bound(duration, MIN_SALE_DURATION, MAX_SALE_DURATION));
    }

    function _boundDurationUnderOf(uint64 duration, uint64 max) internal view returns (uint64) {
        return uint64(bound(duration, 0, max));
    }

    function _boundDurationAboveOf(uint64 duration, uint64 min) internal view returns (uint64) {
        return uint64(bound(duration, min, type(uint64).max));
    }

    function _assumeNotMaintainer(address caller) internal view {
        caller = _boundAddressNotZero(caller);
        vm.assume(caller != maintainer);
    }

    function _boundCommonCreateRaffleParams(uint256 ticketPrice, uint64 ticketSalesDuration, uint16 maxTotalSupply)
        internal
        view
        returns (uint256 _ticketPrice, uint64 _ticketSalesDuration, uint16 _maxTotalSupply)
    {
        _ticketPrice = bound(ticketPrice, MIN_TICKET_PRICE, 1e18);
        _ticketSalesDuration = _boundDuration(ticketSalesDuration);
        _maxTotalSupply = uint16(_bound(maxTotalSupply, 1, MAX_TICKET_SUPPLY));
    }

    function _convertToClooverRaffleParams(
        address purchaseCurrency,
        address nftContract,
        uint256 nftId,
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) internal pure returns (ClooverRaffleTypes.CreateRaffleParams memory) {
        return ClooverRaffleTypes.CreateRaffleParams({
            purchaseCurrency: purchaseCurrency,
            nftContract: nftContract,
            nftId: nftId,
            ticketPrice: ticketPrice,
            ticketSalesDuration: ticketSalesDuration,
            maxTotalSupply: maxTotalSupply,
            maxTicketAllowedToPurchase: maxTicketAllowedToPurchase,
            ticketSalesInsurance: ticketSalesInsurance,
            royaltiesRate: royaltiesRate
        });
    }

    function _convertToPermitDataParams(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (ClooverRaffleTypes.PermitDataParams memory)
    {
        return ClooverRaffleTypes.PermitDataParams({amount: amount, deadline: deadline, v: v, r: r, s: s});
    }

    function _permitData(uint256 privateKey, address spender, uint256 amount)
        internal
        view
        returns (ClooverRaffleTypes.PermitDataParams memory permitData)
    {
        address owner = vm.addr(privateKey);
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: amount,
            nonce: erc20Mock.nonces(owner),
            deadline: 1 days
        });

        bytes32 digest = sigUtils.getTypedDataHash(permit);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        permitData =
            ClooverRaffleTypes.PermitDataParams({amount: permit.value, deadline: permit.deadline, v: v, r: r, s: s});
    }

    function _createDummyRaffle() internal returns (address) {
        changePrank(creator);
        uint256 nftId = 11;
        _mintERC721(erc721Mock, creator, nftId);
        erc721Mock.approve(address(factory), nftId);
        ClooverRaffleTypes.CreateRaffleParams memory params =
            _convertToClooverRaffleParams(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 10_000, 0, 0, 0);
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        return factory.createNewRaffle(params, permitData);
    }

    function _generateRandomNumbersFromRandomProvider(address raffle, bool returnZero) internal {
        uint256 requestId = randomProviderMock.callerToRequestId(raffle);
        if (returnZero) {
            randomProviderMock.requestRandomNumberReturnZero(requestId);
        } else {
            randomProviderMock.generateRandomNumbers(requestId);
        }
    }
}

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
import {ClooverRaffleTypes} from "src/libraries/Types.sol";
import {Errors} from "src/libraries/Errors.sol";
import {ClooverRaffleEvents, ClooverRaffleFactoryEvents} from "src/libraries/Events.sol";

import "./BaseTest.sol";
import "./SigUtils.sol";

contract IntegrationTest is BaseTest {
    using InsuranceLib for uint16;

    SigUtils internal sigUtils;

    AccessController internal accessController;
    ImplementationManager internal implementationManager;
    RandomProviderMock internal randomProviderMock;
    NFTWhitelist internal nftWhitelist;
    TokenWhitelist internal tokenWhitelist;

    ERC721Mock erc721Mock;
    ERC20WithPermitMock erc20Mock;

    ClooverRaffleFactory factory;
    ClooverRaffle raffle;

    uint64 constant MIN_SALE_DURATION = 1 days;
    uint64 constant MAX_SALE_DURATION = 2 weeks;
    uint16 constant MAX_TICKET_SUPPLY = 10000;
    uint16 constant PROTOCOL_FEE_RATE = 2.5e2; // 2.5%
    uint16 constant INSURANCE_RATE = 5e2; //5%

    uint256 constant MIN_TICKET_PRICE = 10000;
    uint256 constant INITIAL_BALANCE = 10_000 ether;

    address internal deployer;
    address internal treasury;
    address internal maintainer;
    address internal collectionCreator;
    address internal creator;
    address internal participant;

    uint256 nftId = 1;

    function setUp() public virtual {
        _initWallets();

        _deployBase();
        _deployRandomProvider();
        _deployNFTWhitelist();
        _deployTokenWhitelist();
        _deployClooverRaffleFactory();

        erc721Mock = _mockERC721(collectionCreator);
        erc20Mock = _mockERC20(18);

        sigUtils = new SigUtils(erc20Mock.DOMAIN_SEPARATOR());

        erc721Mock.mint(creator, nftId);
    }

    function _initWallets() internal {
        deployer = _initUser(1, 0);
        treasury = _initUser(2, 0);
        maintainer = _initUser(3, 0);
        collectionCreator = _initUser(4, 0);
        creator = _initUser(5, INITIAL_BALANCE);
        participant = _initUser(6, INITIAL_BALANCE);

        _label();
    }

    function _label() internal {
        vm.label(deployer, "Deployer");
        vm.label(treasury, "Treasury");
        vm.label(maintainer, "Maintainer");
        vm.label(collectionCreator, "CollectionCreator");
        vm.label(creator, "Creator");
        vm.label(participant, "Participant");
    }

    function _deployBase() internal {
        vm.startPrank(deployer);
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(ImplementationInterfaceNames.Treasury, treasury);
    }

    function _deployRandomProvider() internal {
        changePrank(deployer);
        randomProviderMock = new RandomProviderMock(address(implementationManager));

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.RandomProvider, address(randomProviderMock)
        );
    }

    function _deployNFTWhitelist() internal {
        changePrank(deployer);
        nftWhitelist = new NFTWhitelist(address(implementationManager));
        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.NFTWhitelist, address(nftWhitelist)
        );
    }

    function _deployTokenWhitelist() internal {
        changePrank(deployer);
        tokenWhitelist = new TokenWhitelist(address(implementationManager));
        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.TokenWhitelist, address(tokenWhitelist)
        );
    }

    function _deployClooverRaffleFactory() internal {
        changePrank(deployer);
        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY, PROTOCOL_FEE_RATE, INSURANCE_RATE, MIN_SALE_DURATION, MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(address(implementationManager),configData);

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.ClooverRaffleFactory, address(factory)
        );
    }

    function _initUser(uint256 privateKey, uint256 initialBalance) internal returns (address newUser) {
        newUser = vm.addr(privateKey);
        _setEthBalances(newUser, initialBalance);
    }

    function _setEthBalances(address user, uint256 balance) internal {
        vm.deal(user, balance);
    }

    function _setERC20Balances(address token, address user, uint256 balance) internal {
        deal(token, user, balance / (10 ** (18 - ERC20(token).decimals())));
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

    function _mintERC721(ERC721Mock erc721, address to, uint256 nftId_) internal {
        erc721.mint(to, nftId_);
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
        uint256 nftId_,
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
            nftId: nftId_,
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

    function _signPermitData(uint256 privateKey, address spender, uint256 amount)
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

    function _generateRandomNumbersFromRandomProvider(address raffle_, bool returnZero) internal {
        uint256 requestId = randomProviderMock.callerToRequestId(raffle_);
        if (returnZero) {
            randomProviderMock.requestRandomNumberReturnZero(requestId);
        } else {
            randomProviderMock.generateRandomNumbers(requestId);
        }
    }

    function _createRaffle(
        address purchaseCurrency,
        address nftContract,
        uint256 nftId_,
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) internal returns (ClooverRaffle) {
        erc721Mock.approve(address(factory), nftId_);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            purchaseCurrency,
            nftContract,
            nftId_,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));

        if (ticketSalesInsurance > 0) {
            uint256 insuranceCost = ticketSalesInsurance.calculateInsuranceCost(INSURANCE_RATE, ticketPrice);
            if (purchaseCurrency == address(0)) {
                return ClooverRaffle(factory.createNewRaffle{value: insuranceCost}(params, permitData));
            }
            _setERC20Balances(purchaseCurrency, creator, insuranceCost);
            erc20Mock.approve(address(factory), insuranceCost);
        }

        return ClooverRaffle(factory.createNewRaffle(params, permitData));
    }

    function _createRandomRaffle(bool isEthRaffle, bool hasInsurance, bool hasRoyalties)
        internal
        returns (ClooverRaffle, uint64)
    {
        uint256 ticketPrice = _boundTicketPrice(1e18);
        uint64 ticketSalesDuration = _boundDuration(1 days);
        uint16 maxTotalSupply = uint16(bound(100, 100, MAX_TICKET_SUPPLY));
        uint16 maxTicketAllowedToPurchase = uint16(_boundAmountUnderOf(0, maxTotalSupply));

        uint16 ticketSalesInsurance = 0;
        uint16 royaltiesRate = 0;
        if (hasInsurance) {
            if (maxTicketAllowedToPurchase > 10) {
                ticketSalesInsurance = uint16(_boundAmountNotZeroUnderOf(2, maxTicketAllowedToPurchase));
            } else {
                maxTicketAllowedToPurchase = 0;
                ticketSalesInsurance = uint16(_boundAmountNotZeroUnderOf(2, maxTotalSupply));
            }
        }
        if (hasRoyalties) {
            royaltiesRate =
                uint16(_boundPercentageUnderOf(1, uint16(PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE)));
        }

        ClooverRaffle _raffle = _createRaffle(
            isEthRaffle ? address(0) : address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );

        return (_raffle, ticketSalesDuration);
    }

    function _purchaseRandomAmountOfTickets(ClooverRaffle _raffle, address buyer, uint16 maxTicketToPurchase)
        internal
        returns (uint16 ticketToPurchase)
    {
        changePrank(buyer);
        bool isEthRaffle = _raffle.isEthRaffle();
        uint256 ticketPrice = _raffle.ticketPrice();
        ticketToPurchase = uint16(_boundAmountNotZeroUnderOf(1, maxTicketToPurchase));
        uint256 amount = ticketPrice * ticketToPurchase;
        if (isEthRaffle) {
            _raffle.purchaseTicketsInEth{value: amount}(ticketToPurchase);
        } else {
            _setERC20Balances(address(erc20Mock), buyer, amount);
            erc20Mock.approve(address(_raffle), amount);

            _raffle.purchaseTickets(ticketToPurchase);
        }
        return ticketToPurchase;
    }

    function _purchaseRandomAmountOfTicketsBetween(
        ClooverRaffle _raffle,
        address buyer,
        uint16 minTicketToPurchase,
        uint16 maxTicketToPurchase
    ) internal returns (uint16 ticketToPurchase) {
        changePrank(buyer);
        bool isEthRaffle = _raffle.isEthRaffle();
        uint256 ticketPrice = _raffle.ticketPrice();
        uint16 maxTicketAllowedToPurchase = _raffle.maxTicketAllowedToPurchase();
        if (maxTicketAllowedToPurchase > 0) {
            ticketToPurchase = uint16(bound(1, minTicketToPurchase, maxTicketAllowedToPurchase));
        } else {
            ticketToPurchase = uint16(bound(1, minTicketToPurchase, maxTicketToPurchase));
        }

        uint256 amount = ticketPrice * ticketToPurchase;
        if (isEthRaffle) {
            _raffle.purchaseTicketsInEth{value: amount}(ticketToPurchase);
        } else {
            _setERC20Balances(address(erc20Mock), buyer, amount);
            erc20Mock.approve(address(_raffle), amount);

            _raffle.purchaseTickets(ticketToPurchase);
        }
        return ticketToPurchase;
    }

    function _purchaseExactAmountOfTickets(ClooverRaffle _raffle, address buyer, uint16 ticketToPurchase) internal {
        changePrank(buyer);
        bool isEthRaffle = _raffle.isEthRaffle();
        uint256 ticketPrice = _raffle.ticketPrice();
        uint256 amount = ticketPrice * ticketToPurchase;
        if (isEthRaffle) {
            _raffle.purchaseTicketsInEth{value: amount}(ticketToPurchase);
        } else {
            _setERC20Balances(address(erc20Mock), buyer, amount);
            erc20Mock.approve(address(_raffle), amount);

            _raffle.purchaseTickets(ticketToPurchase);
        }
    }
}

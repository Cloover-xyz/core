// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC20WithPermitMock} from "test/mocks/ERC20WithPermitMock.sol";
import {ERC721Mock} from "test/mocks/ERC721Mock.sol";
import {RandomProviderMock} from "test/mocks/RandomProviderMock.sol";

import {AccessController} from "src/core/AccessController.sol";
import {ImplementationManager} from "src/core/ImplementationManager.sol";
import {NFTWhitelist} from "src/core/NFTWhitelist.sol";
import {TokenWhitelist} from "src/core/TokenWhitelist.sol";
import {RandomProvider} from "src/core/RandomProvider.sol";

import {IClooverRaffleFactory} from "src/interfaces/IClooverRaffleFactory.sol";
import {ClooverRaffleFactory} from "src/raffleFactory/ClooverRaffleFactory.sol";
import {ClooverRaffle} from "src/raffle/ClooverRaffle.sol";

import {InsuranceLib} from "src/libraries/InsuranceLib.sol";
import {ClooverRaffleTypes, RandomProviderTypes} from "src/libraries/Types.sol";
import {Errors} from "src/libraries/Errors.sol";
import {ClooverRaffleEvents, ClooverRaffleFactoryEvents} from "src/libraries/Events.sol";

import "./BaseTest.sol";
import "./SigUtils.sol";

contract IntegrationTest is BaseTest {
    using InsuranceLib for uint16;

    struct RaffleArrayInfo {
        bool isEthRaffle;
        uint256 nftId;
        ClooverRaffle raffle;
    }

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
    uint16 constant PROTOCOL_FEE_RATE = 2_50; // 2.5%
    uint16 constant INSURANCE_RATE = 5_00; //5%

    uint256 constant MIN_TICKET_PRICE = 10_000;
    uint256 constant INITIAL_BALANCE = 10_000 ether;

    address internal deployer;
    address internal treasury;
    address internal maintainer;
    address internal collectionCreator;
    address internal creator;
    address internal participant;
    address internal hacker;

    RaffleArrayInfo[] internal rafflesArray;
    RaffleArrayInfo internal raffleInfo;

    uint256 initialTicketPrice = 1e18;
    uint64 initialTicketSalesDuration = 1 days;
    uint16 initialMaxTotalSupply = 100;
    uint16 initialMaxTicketAllowedToPurchase = 10;
    uint16 initialTicketSalesInsurance = 5;
    uint16 initialRoyaltiesRate = 100; // 1%

    uint256 nftId = 1;
    bool isEthRaffle;
    uint64 blockTimestamp;

    function setUp() public virtual {
        _initWallets();

        _deployBase();
        _mockRandomProvider();
        _deployNFTWhitelist();
        _deployTokenWhitelist();
        _deployClooverRaffleFactory();

        erc721Mock = _mockERC721(collectionCreator);
        erc20Mock = _mockERC20(18);

        sigUtils = new SigUtils(erc20Mock.DOMAIN_SEPARATOR());

        _createAllTokenRafflesTypes();
        _createAllEthRafflesTypes();
        blockTimestamp = uint64(block.timestamp);
    }

    function _initWallets() internal {
        deployer = _initUser(1, 0);
        treasury = _initUser(2, 0);
        maintainer = _initUser(3, 0);
        collectionCreator = _initUser(4, 0);
        creator = _initUser(5, INITIAL_BALANCE);
        participant = _initUser(6, INITIAL_BALANCE);
        hacker = _initUser(7, INITIAL_BALANCE);

        _label();
    }

    function _label() internal {
        vm.label(deployer, "Deployer");
        vm.label(treasury, "Treasury");
        vm.label(maintainer, "Maintainer");
        vm.label(collectionCreator, "CollectionCreator");
        vm.label(creator, "Creator");
        vm.label(participant, "Participant");
        vm.label(hacker, "Hacker");
    }

    function _deployBase() internal {
        vm.startPrank(deployer);
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(ImplementationInterfaceNames.Treasury, treasury);
    }

    function _mockRandomProvider() internal {
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

    function _createAllTokenRafflesTypes() internal {
        changePrank(creator);
        // basic raffle
        uint256 _nftId = 100;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle tokenRaffle = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        rafflesArray.push(RaffleArrayInfo({isEthRaffle: false, nftId: _nftId, raffle: tokenRaffle}));

        // raffle with max ticket allowed to purchase
        _nftId = 101;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle tokenRaffleWithMaxTicketAllowed = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketAllowedToPurchase,
            0,
            0
        );
        rafflesArray.push(RaffleArrayInfo({isEthRaffle: false, nftId: _nftId, raffle: tokenRaffleWithMaxTicketAllowed}));

        // raffle with insurance
        _nftId = 102;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle tokenRaffleWithInsurance = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialTicketSalesInsurance,
            0
        );
        rafflesArray.push(RaffleArrayInfo({isEthRaffle: false, nftId: _nftId, raffle: tokenRaffleWithInsurance}));

        // raffle with royalties
        _nftId = 103;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle tokenRaffleWithRoyalties = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            initialRoyaltiesRate
        );
        rafflesArray.push(RaffleArrayInfo({isEthRaffle: false, nftId: _nftId, raffle: tokenRaffleWithRoyalties}));

        // raffle with insurance & max ticket allowed to purchase
        _nftId = 104;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle tokenRaffleWithInsuranceAndMaxTicketToPurchase = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketAllowedToPurchase,
            initialTicketSalesInsurance,
            0
        );
        rafflesArray.push(
            RaffleArrayInfo({isEthRaffle: false, nftId: _nftId, raffle: tokenRaffleWithInsuranceAndMaxTicketToPurchase})
        );

        // raffle with royalties & insurance
        _nftId = 105;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle tokenRaffleWithRoyaltiesAndInsurance = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialTicketSalesInsurance,
            initialRoyaltiesRate
        );
        rafflesArray.push(
            RaffleArrayInfo({isEthRaffle: false, nftId: _nftId, raffle: tokenRaffleWithRoyaltiesAndInsurance})
        );

        // raffle with royalties & max ticket allowed to purchase
        _nftId = 106;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle tokenRaffleWithRoyaltiesAndMaxTicketAllowedToPurchase = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketAllowedToPurchase,
            0,
            initialRoyaltiesRate
        );
        rafflesArray.push(
            RaffleArrayInfo({
                isEthRaffle: false,
                nftId: _nftId,
                raffle: tokenRaffleWithRoyaltiesAndMaxTicketAllowedToPurchase
            })
        );

        // raffle with royalties & insurance & max ticket allowed to purchase
        _nftId = 107;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle tokenRaffleWithRoyaltiesAndInsuranceAndMaxTicketAllowedToPurchase = _createRaffle(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketAllowedToPurchase,
            initialTicketSalesInsurance,
            initialRoyaltiesRate
        );
        rafflesArray.push(
            RaffleArrayInfo({
                isEthRaffle: false,
                nftId: _nftId,
                raffle: tokenRaffleWithRoyaltiesAndInsuranceAndMaxTicketAllowedToPurchase
            })
        );
    }

    function _createAllEthRafflesTypes() internal {
        changePrank(creator);
        // basic raffle
        uint256 _nftId = 200;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle ethRaffle = _createRaffle(
            address(0),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        rafflesArray.push(RaffleArrayInfo({isEthRaffle: true, nftId: _nftId, raffle: ethRaffle}));

        // raffle with max ticket allowed to purchase
        _nftId = 201;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle ethRaffleWithMaxTicketAllowed = _createRaffle(
            address(0),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketAllowedToPurchase,
            0,
            0
        );
        rafflesArray.push(RaffleArrayInfo({isEthRaffle: true, nftId: _nftId, raffle: ethRaffleWithMaxTicketAllowed}));

        // raffle with insurance
        _nftId = 202;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle ethRaffleWithInsurance = _createRaffle(
            address(0),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialTicketSalesInsurance,
            0
        );
        rafflesArray.push(RaffleArrayInfo({isEthRaffle: true, nftId: _nftId, raffle: ethRaffleWithInsurance}));

        // raffle with royalties
        _nftId = 203;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle ethRaffleWithRoyalties = _createRaffle(
            address(0),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            initialRoyaltiesRate
        );
        rafflesArray.push(RaffleArrayInfo({isEthRaffle: true, nftId: _nftId, raffle: ethRaffleWithRoyalties}));

        // raffle with insurance & max ticket allowed to purchase
        _nftId = 204;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle ethRaffleWithInsuranceAndMaxTicketToPurchase = _createRaffle(
            address(0),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketAllowedToPurchase,
            initialTicketSalesInsurance,
            0
        );
        rafflesArray.push(
            RaffleArrayInfo({isEthRaffle: true, nftId: _nftId, raffle: ethRaffleWithInsuranceAndMaxTicketToPurchase})
        );

        // raffle with royalties & insurance
        _nftId = 205;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle ethRaffleWithRoyaltiesAndInsurance = _createRaffle(
            address(0),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialTicketSalesInsurance,
            initialRoyaltiesRate
        );
        rafflesArray.push(
            RaffleArrayInfo({isEthRaffle: true, nftId: _nftId, raffle: ethRaffleWithRoyaltiesAndInsurance})
        );

        // raffle with royalties & max ticket allowed to purchase
        _nftId = 206;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle ethRaffleWithRoyaltiesAndMaxTicketAllowedToPurchase = _createRaffle(
            address(0),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketAllowedToPurchase,
            0,
            initialRoyaltiesRate
        );
        rafflesArray.push(
            RaffleArrayInfo({
                isEthRaffle: true,
                nftId: _nftId,
                raffle: ethRaffleWithRoyaltiesAndMaxTicketAllowedToPurchase
            })
        );

        // raffle with royalties & insurance & max ticket allowed to purchase
        _nftId = 207;
        erc721Mock.mint(creator, _nftId);
        ClooverRaffle ethRaffleWithRoyaltiesAndInsuranceAndMaxTicketAllowedToPurchase = _createRaffle(
            address(0),
            address(erc721Mock),
            _nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketAllowedToPurchase,
            initialTicketSalesInsurance,
            initialRoyaltiesRate
        );
        rafflesArray.push(
            RaffleArrayInfo({
                isEthRaffle: true,
                nftId: _nftId,
                raffle: ethRaffleWithRoyaltiesAndInsuranceAndMaxTicketAllowedToPurchase
            })
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
    ) internal view returns (ClooverRaffleTypes.CreateRaffleParams memory) {
        return ClooverRaffleTypes.CreateRaffleParams({
            purchaseCurrency: purchaseCurrency,
            nftContract: nftContract,
            nftId: nftId_,
            ticketPrice: ticketPrice,
            endTicketSales: uint64(block.timestamp) + ticketSalesDuration,
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

    function _purchaseExactAmountOfTickets(ClooverRaffle _raffle, address buyer, uint16 ticketToPurchase) internal {
        changePrank(buyer);
        bool _isEthRaffle = _raffle.isEthRaffle();
        uint256 ticketPrice = _raffle.ticketPrice();
        uint256 amount = ticketPrice * ticketToPurchase;
        if (_isEthRaffle) {
            _raffle.purchaseTicketsInEth{value: amount}(ticketToPurchase);
        } else {
            _setERC20Balances(address(erc20Mock), buyer, amount);
            erc20Mock.approve(address(_raffle), amount);

            _raffle.purchaseTickets(ticketToPurchase);
        }
    }
}

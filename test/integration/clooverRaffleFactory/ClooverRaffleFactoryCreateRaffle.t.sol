// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactoryCreateRaffleTest is IntegrationTest {
    using InsuranceLib for uint16;

    function setUp() public virtual override {
        super.setUp();
        _deployClooverRaffleFactory();

        changePrank(creator);
        erc721Mock.mint(creator, nftId);
        erc721Mock.approve(address(factory), nftId);
    }

    function test_CreateRaffle_TokenRaffle() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), 0);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_TokenRaffle_WithMaxTokenAllowedToPurchase() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketPerWallet,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), 0);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), initialMaxTicketPerWallet);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_TokenRaffle_WithInsurance() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        _mintERC20(erc20Mock, creator, insuranceCost);
        erc20Mock.approve(address(factory), insuranceCost);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialMinTicketThreshold,
            0
        );

        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_TokenRaffle_WithInsuranceWithPermit() external {
        uint256 creatorPrivateKey = 5;

        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        _mintERC20(erc20Mock, creator, insuranceCost);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _signPermitData(creatorPrivateKey, address(factory), insuranceCost);

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialMinTicketThreshold,
            0
        );

        changePrank(creator);
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_TokenRaffle_WithRoyalties() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            initialRoyaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), 0);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), initialRoyaltiesRate);
    }

    function test_CreateRaffle_TokenRaffle_WithMaxTokenAllowedToPurchase_And_Insurance() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        _mintERC20(erc20Mock, creator, insuranceCost);
        erc20Mock.approve(address(factory), insuranceCost);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketPerWallet,
            initialMinTicketThreshold,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), initialMaxTicketPerWallet);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_TokenRaffle_WithMaxTokenAllowedToPurchase_And_Royalties() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketPerWallet,
            0,
            initialRoyaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), 0);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), initialMaxTicketPerWallet);
        assertEq(newRaffle.royaltiesRate(), initialRoyaltiesRate);
    }

    function test_CreateRaffle_TokenRaffle_WithInsurance_And_Royalties() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        _mintERC20(erc20Mock, creator, insuranceCost);
        erc20Mock.approve(address(factory), insuranceCost);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialMinTicketThreshold,
            initialRoyaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), initialRoyaltiesRate);
    }

    function test_CreateRaffle_TokenRaffle_WithMaxTokenAllowedToPurchase_And_Insurance_And_Royalties() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        _mintERC20(erc20Mock, creator, insuranceCost);
        erc20Mock.approve(address(factory), insuranceCost);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketPerWallet,
            initialMinTicketThreshold,
            initialRoyaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), initialMaxTicketPerWallet);
        assertEq(newRaffle.royaltiesRate(), initialRoyaltiesRate);
    }

    function test_CreateRaffle_TokenRaffle_RevertWhen_CreatorFundsDoesntCoverInsuranceCost() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialMinTicketThreshold,
            0
        );

        vm.expectRevert();
        ClooverRaffle(factory.createRaffle(params, permitData));

        uint256 creatorPrivateKey = 5;
        permitData = _signPermitData(creatorPrivateKey, address(factory), insuranceCost);
        vm.expectRevert();
        ClooverRaffle(factory.createRaffle(params, permitData));
    }

    function test_CreateRaffle_EthRaffle() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(address(newRaffle).balance, 0);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_EthRaffle_WithMaxTokenAllowedToPurchase() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketPerWallet,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(address(newRaffle).balance, 0);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), initialMaxTicketPerWallet);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_EthRaffle_WithInsurance() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialMinTicketThreshold,
            0
        );

        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle{value: insuranceCost}(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(address(newRaffle).balance, insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_EthRaffle_WithRoyalties() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            initialRoyaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(address(newRaffle).balance, 0);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), initialRoyaltiesRate);
    }

    function test_CreateRaffle_EthRaffle_WithMaxTokenAllowedToPurchase_And_Insurance() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketPerWallet,
            initialMinTicketThreshold,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle{value: insuranceCost}(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(address(newRaffle).balance, insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), initialMaxTicketPerWallet);
        assertEq(newRaffle.royaltiesRate(), 0);
    }

    function test_CreateRaffle_EthRaffle_WithMaxTokenAllowedToPurchase_And_Royalties() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketPerWallet,
            0,
            initialRoyaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(address(newRaffle).balance, 0);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), initialMaxTicketPerWallet);
        assertEq(newRaffle.royaltiesRate(), initialRoyaltiesRate);
    }

    function test_CreateRaffle_EthRaffle_WithInsurance_And_Royalties() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialMinTicketThreshold,
            initialRoyaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle{value: insuranceCost}(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(address(newRaffle).balance, insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), 0);
        assertEq(newRaffle.royaltiesRate(), initialRoyaltiesRate);
    }

    function test_CreateRaffle_EthRaffle_WithMaxTokenAllowedToPurchase_And_Insurance_And_Royalties() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            initialMaxTicketPerWallet,
            initialMinTicketThreshold,
            initialRoyaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createRaffle{value: insuranceCost}(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(address(newRaffle).balance, insuranceCost);
        assertEq(newRaffle.creator(), creator);
        assertEq(newRaffle.maxTicketPerWallet(), initialMaxTicketPerWallet);
        assertEq(newRaffle.royaltiesRate(), initialRoyaltiesRate);
    }

    function test_CreateRaffle_EthRaffle_RevertWhen_ValueSendNotEqualToInsuranceCost() external {
        uint256 insuranceCost =
            initialMinTicketThreshold.calculateInsuranceCost(uint16(factory.insuranceRate()), initialTicketPrice);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            initialMinTicketThreshold,
            0
        );

        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        ClooverRaffle(factory.createRaffle{value: insuranceCost - 1}(params, permitData));

        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        ClooverRaffle(factory.createRaffle{value: insuranceCost + 1}(params, permitData));
    }

    function test_CreateRaffle_RevertWhen_NFTNotWhitelisted() external {
        address notWhiteListedNFTCollection = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(notWhiteListedNFTCollection),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_TokenRaffle_RevertWhen_HasMsgValue() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        factory.createRaffle{value: 1}(params, permitData);
    }

    function test_CreateRaffle_TokenRaffle_RevertWhen_TokenNotWhitelisted() external {
        address notWhiteListedToken = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            notWhiteListedToken,
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.TOKEN_NOT_WHITELISTED.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_TicketPriceIsUnderMininumPrice() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            MIN_TICKET_PRICE - 1,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.WRONG_AMOUNT.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_MaxTicketSupplyIsZero() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock), address(erc721Mock), nftId, initialTicketPrice, initialTicketSalesDuration, 0, 0, 0, 0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_MaxTicketSupplyHigherThenMaxTotalSupplyAllowed() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            MAX_TICKET_SUPPLY + 1,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_MaxTicketSupplyLowerThenTwo() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock), address(erc721Mock), nftId, initialTicketPrice, initialTicketSalesDuration, 1, 0, 0, 0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.BELOW_MIN_VALUE_ALLOWED.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_SaleDurationLowerThanMinTicketSalesDuration() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            MIN_SALE_DURATION - 1,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_SaleDurationHigherThanMaxTicketSalesDuration() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            MAX_SALE_DURATION + 1,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_RoyaltiesRateMakeTotalFeesExceedMaxPercentage() external {
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            uint16(PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE + 1)
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        factory.createRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_ContractIsPause() external {
        changePrank(maintainer);
        factory.pause();

        changePrank(creator);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            initialTicketPrice,
            initialTicketSalesDuration,
            initialMaxTotalSupply,
            0,
            0,
            0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));

        vm.expectRevert();
        ClooverRaffle(factory.createRaffle(params, permitData));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactoryCreateRaffleTest is IntegrationTest {
    using InsuranceLib for uint16;

    function setUp() public virtual override {
        super.setUp();

        changePrank(creator);
        erc721Mock.approve(address(factory), nftId);
    }

    function test_CreateNewRaffle_NotEthRaffle_WithoutInsurance(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 royaltiesRate
    ) external {
        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            0,
            royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createNewRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(newRaffle.creator(), creator);
    }

    function test_CreateNewRaffle_NotEthRaffle_WithInsurance(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) external {
        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        uint256 insuranceCost =
            ticketSalesInsurance.calculateInsuranceCost(uint16(factory.insuranceRate()), ticketPrice);

        _mintERC20(erc20Mock, creator, insuranceCost);
        erc20Mock.approve(address(factory), insuranceCost);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );

        ClooverRaffle newRaffle = ClooverRaffle(factory.createNewRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), insuranceCost);
        assertEq(newRaffle.creator(), creator);
    }

    function test_CreateNewRaffle_NotEthRaffle_WithInsuranceWithPermit(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) external {
        uint256 creatorPrivateKey = 0xA11ce;
        address creatorPublicKey = vm.addr(creatorPrivateKey);

        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        uint256 insuranceCost =
            ticketSalesInsurance.calculateInsuranceCost(uint16(factory.insuranceRate()), ticketPrice);

        uint256 _nftId = 11;
        _mintERC721(erc721Mock, creatorPublicKey, _nftId);
        _mintERC20(erc20Mock, creatorPublicKey, insuranceCost);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _signPermitData(creatorPrivateKey, address(factory), insuranceCost);

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );

        changePrank(creatorPublicKey);
        erc721Mock.approve(address(factory), _nftId);
        ClooverRaffle newRaffle = ClooverRaffle(factory.createNewRaffle(params, permitData));
        assertFalse(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(erc20Mock.balanceOf(address(newRaffle)), insuranceCost);
        assertEq(newRaffle.creator(), creatorPublicKey);
    }

    function test_CreateNewRaffle_isEthRaffle_WithoutInsurance(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 royaltiesRate
    ) external {
        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            0,
            royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createNewRaffle(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), 0);
        assertEq(newRaffle.creator(), creator);
    }

    function test_CreateNewRaffle_isEthRaffle_WithInsurance(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) external {
        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        uint256 insuranceCost =
            ticketSalesInsurance.calculateInsuranceCost(uint16(factory.insuranceRate()), ticketPrice);

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        ClooverRaffle newRaffle = ClooverRaffle(factory.createNewRaffle{value: insuranceCost}(params, permitData));
        assertTrue(newRaffle.isEthRaffle());
        assertEq(newRaffle.insurancePaid(), insuranceCost);
        assertEq(address(newRaffle).balance, insuranceCost);
        assertEq(newRaffle.creator(), creator);
    }

    function test_CreateNewRaffle_RevertWhen_IsEthRaffleAndHasMsgValueUnderRequired(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) external {
        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        uint256 insuranceCost =
            ticketSalesInsurance.calculateInsuranceCost(uint16(factory.insuranceRate()), ticketPrice);
        insuranceCost = _boundAmountUnderOf(insuranceCost, insuranceCost - 1);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        ClooverRaffle(factory.createNewRaffle{value: insuranceCost}(params, permitData));
    }

    function test_CreateNewRaffle_RevertWhen_IsEthRaffleAndHasMsgValueAboveRequired(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate
    ) external {
        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        uint256 insuranceCost =
            ticketSalesInsurance.calculateInsuranceCost(uint16(factory.insuranceRate()), ticketPrice);
        insuranceCost = bound(insuranceCost, insuranceCost + 1, INITIAL_BALANCE);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(0),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        ClooverRaffle(factory.createNewRaffle{value: insuranceCost}(params, permitData));
    }

    function test_CreateRaffle_RevertWhen_NFTNotWhitelisted(address nftCollection) external {
        vm.assume(nftCollection != address(erc721Mock));
        ClooverRaffleTypes.CreateRaffleParams memory params =
            _convertToClooverRaffleParams(address(erc20Mock), nftCollection, nftId, 1e18, 1 days, 100, 1, 0, 0);
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        factory.createNewRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_IsNotEthRaffleAndHasMsgValue(uint256 value) external {
        value = _boundEthAmount(value);
        ClooverRaffleTypes.CreateRaffleParams memory params =
            _convertToClooverRaffleParams(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 100, 1, 0, 0);
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.NOT_ETH_RAFFLE.selector);
        factory.createNewRaffle{value: value}(params, permitData);
    }

    function test_CreateRaffle_TokenRaffle_RevertWhen_TokenNotWhitelisted(address token) external {
        token = _boundAddressNotZero(token);
        vm.assume(token != address(erc20Mock));
        console2.log(token);
        console2.log(address(erc20Mock));
        ClooverRaffleTypes.CreateRaffleParams memory params =
            _convertToClooverRaffleParams(token, address(erc721Mock), nftId, 1e18, 1 days, 100, 1, 0, 0);
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.TOKEN_NOT_WHITELISTED.selector);
        factory.createNewRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_TicketPriceIsZero(uint256 ticketPrice) external {
        ticketPrice = _boundAmountUnderOf(ticketPrice, MIN_TICKET_PRICE - 1);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock), address(erc721Mock), nftId, ticketPrice, 1 days, 100, 1, 0, 0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.WRONG_AMOUNT.selector);
        factory.createNewRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_MaxTicketSupplyIsZero() external {
        ClooverRaffleTypes.CreateRaffleParams memory params =
            _convertToClooverRaffleParams(address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 0, 1, 0, 0);
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        factory.createNewRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_MaxTicketSupplyHigherThenMaxTotalSupplyAllowed(uint16 ticketSupply)
        external
    {
        ticketSupply = _boundUint16AmountAboveOf(ticketSupply, uint16(factory.maxTotalSupplyAllowed()) + 1);
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, MAX_TICKET_SUPPLY + 1, 1, 0, 0
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.EXCEED_MAX_VALUE_ALLOWED.selector);
        factory.createNewRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_SaleDurationLowerThanMinTicketSalesDuration(uint64 duration) external {
        duration = _boundDurationUnderOf(duration, uint64(factory.minTicketSalesDuration()));
        ClooverRaffleTypes.CreateRaffleParams memory params =
            _convertToClooverRaffleParams(address(erc20Mock), address(erc721Mock), nftId, 1e18, duration, 100, 1, 0, 0);
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        factory.createNewRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_SaleDurationHigherThanMaxTicketSalesDuration(uint64 duration) external {
        duration = _boundDurationAboveOf(duration, uint64(factory.maxTicketSalesDuration()) + 1);
        ClooverRaffleTypes.CreateRaffleParams memory params =
            _convertToClooverRaffleParams(address(erc20Mock), address(erc721Mock), nftId, 1e18, duration, 100, 1, 0, 0);
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.OUT_OF_RANGE.selector);
        factory.createNewRaffle(params, permitData);
    }

    function test_CreateRaffle_RevertWhen_RoyaltiesRateMakeTotalFeesHigherThanPercentageFactory(uint16 royaltiesRate)
        external
    {
        uint16 prototocolFeeRate = uint16(factory.protocolFeeRate());
        vm.assume(royaltiesRate <= type(uint16).max - prototocolFeeRate);

        royaltiesRate = _boundPercentageExceed(royaltiesRate + prototocolFeeRate) - prototocolFeeRate;
        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock), address(erc721Mock), nftId, 1e18, 1 days, 100, 1, 0, royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        factory.createNewRaffle(params, permitData);
    }

    function test_CreateNewRaffle_RevertWhen_PermitAmountLessThanInsurance(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 ticketSalesInsurance,
        uint16 royaltiesRate,
        uint256 privateKey
    ) external {
        privateKey = bound(privateKey, 1, type(uint160).max);
        address creator = vm.addr(privateKey);

        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        ticketSalesInsurance = uint16(bound(ticketSalesInsurance, 1, maxTotalSupply));
        uint256 insuranceCost =
            ticketSalesInsurance.calculateInsuranceCost(uint16(factory.insuranceRate()), ticketPrice);
        insuranceCost = _boundAmountUnderOf(insuranceCost, insuranceCost - 1);
        uint256 _nftId = 11;
        _mintERC721(erc721Mock, creator, _nftId);
        _mintERC20(erc20Mock, creator, insuranceCost);

        ClooverRaffleTypes.PermitDataParams memory permitData =
            _signPermitData(privateKey, address(factory), insuranceCost);

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            _nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            ticketSalesInsurance,
            royaltiesRate
        );

        changePrank(creator);
        erc721Mock.approve(address(factory), _nftId);
        vm.expectRevert(Errors.INSURANCE_AMOUNT.selector);
        ClooverRaffle(factory.createNewRaffle(params, permitData));
    }

    function test_CreateNewRaffle_RevertWhen_ContractIsPause(
        uint256 ticketPrice,
        uint64 ticketSalesDuration,
        uint16 maxTotalSupply,
        uint16 maxTicketAllowedToPurchase,
        uint16 royaltiesRate
    ) external {
        changePrank(maintainer);
        factory.pause();

        changePrank(creator);

        (ticketPrice, ticketSalesDuration, maxTotalSupply) =
            _boundCommonCreateRaffleParams(ticketPrice, ticketSalesDuration, maxTotalSupply);
        royaltiesRate = uint16(_boundAmountUnderOf(royaltiesRate, PercentageMath.PERCENTAGE_FACTOR - PROTOCOL_FEE_RATE));

        ClooverRaffleTypes.CreateRaffleParams memory params = _convertToClooverRaffleParams(
            address(erc20Mock),
            address(erc721Mock),
            nftId,
            ticketPrice,
            ticketSalesDuration,
            maxTotalSupply,
            maxTicketAllowedToPurchase,
            0,
            royaltiesRate
        );
        ClooverRaffleTypes.PermitDataParams memory permitData =
            _convertToPermitDataParams(0, 0, 0, bytes32(0), bytes32(0));
        vm.expectRevert();
        ClooverRaffle(factory.createNewRaffle(params, permitData));
    }
}

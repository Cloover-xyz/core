// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactorySettersTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        changePrank(maintainer);
    }

    function test_Initialized() external {
        assertEq(factory.protocolFeeRate(), PROTOCOL_FEE_RATE);
        assertEq(factory.insuranceRate(), INSURANCE_RATE);
        assertEq(factory.minTicketSalesDuration(), MIN_SALE_DURATION);
        assertEq(factory.maxTicketSalesDuration(), MAX_SALE_DURATION);
        assertEq(factory.maxTotalSupplyAllowed(), MAX_TICKET_SUPPLY);
        assertEq(address(factory.implementationManager()), address(implementationManager));
    }

    function test_Initialized_RevertWhen_MaxSupplyAllowed_IsZero() external {
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            0, PROTOCOL_FEE_RATE, INSURANCE_RATE, MIN_SALE_DURATION, MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(
         address(implementationManager),
         configData
      );
    }

    function test_Initialized_RevertWhen_ProtocolFeeRate_ExceedMaxPercentage(uint16 protocolFeeRate) external {
        protocolFeeRate = _boundPercentageExceed(protocolFeeRate);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY, protocolFeeRate, INSURANCE_RATE, MIN_SALE_DURATION, MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(
         address(implementationManager),
         configData
      );
    }

    function test_Initialized_RevertWhen_InsuranceRate_ExceedMaxPercentage(uint16 insuranceRate) external {
        insuranceRate = _boundPercentageExceed(insuranceRate);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY, PROTOCOL_FEE_RATE, insuranceRate, MIN_SALE_DURATION, MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(
         address(implementationManager),
         configData
      );
    }

    function test_Initialized_RevertWhen_MinTicketSalesDuration_GreaterThan_MaxTicketSalesDuration(
        uint64 minTicketSalesDuration,
        uint64 maxTicketSalesDuration
    ) external {
        minTicketSalesDuration = _boundDurationAboveOf(minTicketSalesDuration, maxTicketSalesDuration);
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY, PROTOCOL_FEE_RATE, INSURANCE_RATE, minTicketSalesDuration, maxTicketSalesDuration
        );
        factory = new ClooverRaffleFactory(
         address(implementationManager),
         configData
      );
    }

    function test_SetProtocolFeeRate(uint16 protocolFeeRate) external {
        protocolFeeRate = _boundPercentage(protocolFeeRate);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.ProtocolFeeRateUpdated(protocolFeeRate);

        factory.setProtocolFeeRate(protocolFeeRate);

        assertEq(factory.protocolFeeRate(), protocolFeeRate);
    }

    function test_SetProtocolFeeRate_RevertWhen_ExceedsMax(uint16 protocolFeeRate) external {
        protocolFeeRate = _boundPercentageExceed(protocolFeeRate);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        factory.setProtocolFeeRate(protocolFeeRate);
    }

    function test_SetProtocolFeeRate_RevertIf_NotMaintainer(uint16 protocolFeeRate, address caller) external {
        _assumeNotMaintainer(caller);
        changePrank(caller);
        protocolFeeRate = _boundPercentage(protocolFeeRate);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setProtocolFeeRate(protocolFeeRate);
    }

    function test_SetInsuranceRate(uint16 insuranceRate) external {
        insuranceRate = _boundPercentage(insuranceRate);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.InsuranceRateUpdated(insuranceRate);

        factory.setInsuranceRate(insuranceRate);
        assertEq(factory.insuranceRate(), insuranceRate);
    }

    function test_SetInsuranceRate_RevertWhen_ExceedMax(uint16 insuranceRate) external {
        insuranceRate = _boundPercentageExceed(insuranceRate);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        factory.setInsuranceRate(insuranceRate);
    }

    function test_SetInsuranceRate_RevertIf_NotMaintainer(uint16 insuranceRate, address caller) external {
        _assumeNotMaintainer(caller);
        changePrank(caller);
        insuranceRate = _boundPercentage(insuranceRate);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setInsuranceRate(insuranceRate);
    }

    function test_SetMinTicketSalesDuration(uint64 minTicketSalesDuration) external {
        minTicketSalesDuration = _boundDurationUnderOf(minTicketSalesDuration, uint64(factory.maxTicketSalesDuration()));

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.MinTicketSalesDurationUpdated(minTicketSalesDuration);

        factory.setMinTicketSalesDuration(minTicketSalesDuration);
        assertEq(factory.minTicketSalesDuration(), minTicketSalesDuration);
    }

    function test_SetMinTicketSalesDuration_RevertWhen_ExceedsMax(uint64 minTicketSalesDuration) external {
        minTicketSalesDuration = _boundDurationAboveOf(minTicketSalesDuration, uint64(factory.maxTicketSalesDuration()));
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        factory.setMinTicketSalesDuration(minTicketSalesDuration);
    }

    function test_SetMinTicketSalesDuration_RevertIf_NotMaintainer(uint64 minTicketSalesDuration, address caller)
        external
    {
        _assumeNotMaintainer(caller);
        changePrank(caller);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMinTicketSalesDuration(minTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration(uint64 maxTicketSalesDuration) external {
        maxTicketSalesDuration =
            _boundDurationAboveOf(maxTicketSalesDuration, uint64(factory.minTicketSalesDuration()) + 1);

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.MaxTicketSalesDurationUpdated(maxTicketSalesDuration);

        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
        assertEq(factory.maxTicketSalesDuration(), maxTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration_RevertWhen_LowerThanMin(uint64 maxTicketSalesDuration) external {
        maxTicketSalesDuration = _boundDurationUnderOf(maxTicketSalesDuration, uint64(factory.minTicketSalesDuration()));
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration_RevertIf_NotMaintainer(uint64 maxTicketSalesDuration, address caller)
        external
    {
        _assumeNotMaintainer(caller);
        changePrank(caller);

        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
    }

    function test_SetMaxTotalSupplyAllowed(uint16 maxTotalSupplyAllowed) external {
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.MaxTotalSupplyAllowedUpdated(maxTotalSupplyAllowed);

        factory.setMaxTotalSupplyAllowed(maxTotalSupplyAllowed);

        assertEq(factory.maxTotalSupplyAllowed(), maxTotalSupplyAllowed);
    }

    function test_SetMaxTotalSupplyAllowed_RevertIf_NotMaintainer(uint16 maxTotalSupplyAllowed, address caller)
        external
    {
        _assumeNotMaintainer(caller);
        changePrank(caller);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMaxTotalSupplyAllowed(maxTotalSupplyAllowed);
    }

    function test_Pause() external {
        factory.pause();

        assertTrue(factory.paused());
    }

    function test_Pause_RevertIf_NotMaintainer(address caller) external {
        _assumeNotMaintainer(caller);
        changePrank(caller);

        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.pause();
    }

    function test_Unpause() external {
        factory.pause();
        factory.unpause();

        assertFalse(factory.paused());
    }

    function test_Unpause_RevertIf_NotMaintainer(address caller) external {
        _assumeNotMaintainer(caller);

        factory.pause();

        changePrank(caller);

        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.pause();
    }
}

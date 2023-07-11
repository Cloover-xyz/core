// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactorySettersTest is IntegrationTest {
    function setUp() public virtual override {
        super.setUp();
        _deployClooverRaffleFactory();

        changePrank(maintainer);
    }

    function test_Initialized() external {
        assertEq(factory.protocolFeeRate(), PROTOCOL_FEE_RATE);
        assertEq(factory.insuranceRate(), INSURANCE_RATE);
        assertEq(factory.minTicketSalesDuration(), MIN_SALE_DURATION);
        assertEq(factory.maxTicketSalesDuration(), MAX_SALE_DURATION);
        assertEq(factory.maxTicketSupplyAllowed(), MAX_TICKET_SUPPLY);
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

    function test_Initialized_RevertWhen_ProtocolFeeRate_ExceedMaxPercentage() external {
        uint16 protocolFeeRate = uint16(PercentageMath.PERCENTAGE_FACTOR + 1);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY, protocolFeeRate, INSURANCE_RATE, MIN_SALE_DURATION, MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(
            address(implementationManager),
            configData
        );
    }

    function test_Initialized_RevertWhen_InsuranceRate_ExceedMaxPercentage() external {
        uint16 insuranceRate = uint16(PercentageMath.PERCENTAGE_FACTOR + 1);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY, PROTOCOL_FEE_RATE, insuranceRate, MIN_SALE_DURATION, MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(
            address(implementationManager),
            configData
        );
    }

    function test_Initialized_RevertWhen_MinTicketSalesDuration_GreaterThan_MaxTicketSalesDuration() external {
        uint64 minTicketSalesDuration = MAX_SALE_DURATION + 1;
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        ClooverRaffleTypes.FactoryConfigParams memory configData = ClooverRaffleTypes.FactoryConfigParams(
            MAX_TICKET_SUPPLY, PROTOCOL_FEE_RATE, INSURANCE_RATE, minTicketSalesDuration, MAX_SALE_DURATION
        );
        factory = new ClooverRaffleFactory(
            address(implementationManager),
            configData
        );
    }

    function test_SetProtocolFeeRate() external {
        uint16 protocolFeeRate = 1000; // 10%
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.ProtocolFeeRateUpdated(protocolFeeRate);

        factory.setProtocolFeeRate(protocolFeeRate);

        assertEq(factory.protocolFeeRate(), protocolFeeRate);
    }

    function test_SetProtocolFeeRate_RevertWhen_ExceedsMax() external {
        uint16 protocolFeeRate = uint16(PercentageMath.PERCENTAGE_FACTOR + 1); // 100.01%

        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        factory.setProtocolFeeRate(protocolFeeRate);
    }

    function test_SetProtocolFeeRate_RevertIf_NotMaintainer() external {
        uint16 protocolFeeRate = 1000; // 10%

        changePrank(hacker);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setProtocolFeeRate(protocolFeeRate);
    }

    function test_SetInsuranceRate() external {
        uint16 insuranceRate = 1000; // 10%

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.InsuranceRateUpdated(insuranceRate);

        factory.setInsuranceRate(insuranceRate);
        assertEq(factory.insuranceRate(), insuranceRate);
    }

    function test_SetInsuranceRate_RevertWhen_NewRateExceedMaxPercentage() external {
        uint16 insuranceRate = uint16(PercentageMath.PERCENTAGE_FACTOR + 1); // 100.01%
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        factory.setInsuranceRate(insuranceRate);
    }

    function test_SetInsuranceRate_RevertIf_NotMaintainer() external {
        uint16 insuranceRate = 1000; // 10%
        changePrank(hacker);

        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setInsuranceRate(insuranceRate);
    }

    function test_SetMinTicketSalesDuration() external {
        uint64 minTicketSalesDuration = 2 days;
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.MinTicketSalesDurationUpdated(minTicketSalesDuration);

        factory.setMinTicketSalesDuration(minTicketSalesDuration);
        assertEq(factory.minTicketSalesDuration(), minTicketSalesDuration);
    }

    function test_SetMinTicketSalesDuration_RevertWhen_ExceedsMaxDuration() external {
        uint64 minTicketSalesDuration = MAX_SALE_DURATION + 1;
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        factory.setMinTicketSalesDuration(minTicketSalesDuration);
    }

    function test_SetMinTicketSalesDuration_RevertIf_NotMaintainer() external {
        uint64 minTicketSalesDuration = 2 days;
        changePrank(hacker);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMinTicketSalesDuration(minTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration() external {
        uint64 maxTicketSalesDuration = 2 weeks;

        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.MaxTicketSalesDurationUpdated(maxTicketSalesDuration);

        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
        assertEq(factory.maxTicketSalesDuration(), maxTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration_RevertWhen_LowerThanMinDuration() external {
        uint64 maxTicketSalesDuration = MIN_SALE_DURATION - 1;
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration_RevertIf_NotMaintainer() external {
        uint64 maxTicketSalesDuration = 2 weeks;

        changePrank(hacker);

        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
    }

    function test_SetMaxTotalSupplyAllowed() external {
        uint16 maxTicketSupplyAllowed = 1000;
        vm.expectEmit(true, true, true, true);
        emit ClooverRaffleFactoryEvents.MaxTotalSupplyAllowedUpdated(maxTicketSupplyAllowed);

        factory.setMaxTicketSupplyAllowed(maxTicketSupplyAllowed);

        assertEq(factory.maxTicketSupplyAllowed(), maxTicketSupplyAllowed);
    }

    function test_SetMaxTotalSupplyAllowed_RevertIf_NotMaintainer() external {
        uint16 maxTicketSupplyAllowed = 1000;
        changePrank(hacker);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMaxTicketSupplyAllowed(maxTicketSupplyAllowed);
    }

    function test_Pause() external {
        factory.pause();

        assertTrue(factory.paused());
    }

    function test_Pause_RevertIf_NotMaintainer() external {
        changePrank(hacker);

        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.pause();
    }

    function test_Unpause() external {
        factory.pause();
        factory.unpause();

        assertFalse(factory.paused());
    }

    function test_Unpause_RevertIf_NotMaintainer() external {
        factory.pause();

        changePrank(hacker);

        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.pause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ClooverRaffleFactorySettersTest is IntegrationTest {

    function setUp() public virtual override {
        super.setUp();
    }

    function test_SetProtocolFeeRate(uint16 protocolFeeRate) external {
        changePrank(address(maintainer));
        protocolFeeRate = _boundPercentage(protocolFeeRate);
        factory.setProtocolFeeRate(protocolFeeRate);
        assertEq(factory.protocolFeeRate(), protocolFeeRate);
    }

    function test_SetProtocolFeeRate_RevertWhen_ExceedsMax(uint16 protocolFeeRate) external {
        changePrank(address(maintainer));
        protocolFeeRate = _boundPercentageExceed(protocolFeeRate);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        factory.setProtocolFeeRate(protocolFeeRate);
    }

    function test_SetProtocolFeeRate_RevertIf_NotMaintainer(uint16 protocolFeeRate, address caller) external {
        vm.assume(caller != address(maintainer));
        changePrank(caller);
        protocolFeeRate = _boundPercentage(protocolFeeRate);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setProtocolFeeRate(protocolFeeRate);
    }

    function test_SetInsuranceRate(uint16 insuranceRate) external {
        changePrank(address(maintainer));
        insuranceRate = _boundPercentage(insuranceRate);
        factory.setInsuranceRate(insuranceRate);
        assertEq(factory.insuranceRate(), insuranceRate);
    }

    function test_SetInsuranceRate_RevertWhen_ExceedMax(uint16 insuranceRate) external {
        changePrank(address(maintainer));
        insuranceRate = _boundPercentageExceed(insuranceRate);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        factory.setInsuranceRate(insuranceRate);
    }

    function test_SetInsuranceRate_RevertIf_NotMaintainer(uint16 insuranceRate, address caller) external {
        vm.assume(caller != address(maintainer));
        changePrank(caller);
        insuranceRate = _boundPercentage(insuranceRate);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setInsuranceRate(insuranceRate);
    }

    function test_SetMinTicketSalesDuration(uint64 minTicketSalesDuration) external {
        changePrank(address(maintainer));
        minTicketSalesDuration =_boundMinSaleDuration(minTicketSalesDuration);
        factory.setMinTicketSalesDuration(minTicketSalesDuration);
        assertEq(factory.minTicketSalesDuration(), minTicketSalesDuration);
    }

    function test_SetMinTicketSalesDuration_RevertWhen_ExceedsMax(uint64 minTicketSalesDuration) external {
        changePrank(address(maintainer));
        minTicketSalesDuration = _boundMinSaleDurationExceedMax(minTicketSalesDuration);
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        factory.setMinTicketSalesDuration(minTicketSalesDuration);
    }

    function test_SetMinTicketSalesDuration_RevertIf_NotMaintainer(uint64 minTicketSalesDuration, address caller) external {
        vm.assume(caller != address(maintainer));
        changePrank(caller);
        minTicketSalesDuration = _boundMinSaleDuration(minTicketSalesDuration);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMinTicketSalesDuration(minTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration(uint64 maxTicketSalesDuration) external {
        changePrank(address(maintainer));
        maxTicketSalesDuration =_boundMinSaleDuration(maxTicketSalesDuration);
        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
        assertEq(factory.maxTicketSalesDuration(), maxTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration_RevertWhen_ExceedsMax(uint64 maxTicketSalesDuration) external {
        changePrank(address(maintainer));
        maxTicketSalesDuration = _boundMinSaleDurationExceedMax(maxTicketSalesDuration);
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration_RevertIf_NotMaintainer(uint64 maxTicketSalesDuration, address caller) external {
        vm.assume(caller != address(maintainer));
        changePrank(caller);
        maxTicketSalesDuration = _boundMinSaleDuration(maxTicketSalesDuration);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMaxTicketSalesDuration(maxTicketSalesDuration);
    }
    
    function test_SetMaxTotalSupplyAllowed(uint16 maxTotalSupplyAllowed) external {
        changePrank(address(maintainer));
        factory.setMaxTotalSupplyAllowed(maxTotalSupplyAllowed);
        assertEq(factory.maxTotalSupplyAllowed(), maxTotalSupplyAllowed);
    }

    function test_SetMaxTotalSupplyAllowed_RevertIf_NotMaintainer(uint16 maxTotalSupplyAllowed, address caller) external {
        vm.assume(caller != address(maintainer));
        changePrank(caller);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        factory.setMaxTotalSupplyAllowed(maxTotalSupplyAllowed);
    }
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {ConfigManager} from "../../../src/core/ConfigManager.sol";

import {ConfigManagerDataTypes} from "../../../src/libraries/types/ConfigManagerDataTypes.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";


contract ConfigManagerTest is Test, SetupUsers {

    AccessController accessController;
    ImplementationManager implementationManager;
    ConfigManager configManager;

    uint16 protocolFeeRate = 1e2; // 1%
    uint16 insuranceRate = 5e2; // 5%
    uint16 maxTotalSupplyAllowed = 10000; 
    uint64 minTicketSalesDuration = 86400; // 1 days
    uint64 maxTicketSalesDuration = 8 weeks; // 2 months

    function setUp() public virtual override {
        SetupUsers.setUp(); 
        vm.startPrank(deployer);
        
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));

        ConfigManagerDataTypes.InitConfigManagerParams memory data = ConfigManagerDataTypes.InitConfigManagerParams(
            maxTotalSupplyAllowed,
            protocolFeeRate,
            insuranceRate,
            minTicketSalesDuration,
            maxTicketSalesDuration
        );
        configManager = new ConfigManager(implementationManager, data);

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.ConfigManager,
              address(configManager)
        );
    }

    function test_Deployment() external {
        assertEq(address(configManager.implementationManager()), address(implementationManager));
        assertEq(implementationManager.getImplementationAddress(ImplementationInterfaceNames.ConfigManager), address(configManager));
        assertEq(configManager.protocolFeeRate(), protocolFeeRate);
        assertEq(configManager.minTicketSalesDuration(), minTicketSalesDuration);
        assertEq(configManager.maxTicketSalesDuration(), maxTicketSalesDuration);
        assertEq(configManager.maxTotalSupplyAllowed(), maxTotalSupplyAllowed);
        (uint256 min, uint256 max) = configManager.ticketSalesDurationLimits();
        assertEq(min, minTicketSalesDuration);
        assertEq(max, maxTicketSalesDuration);
    }
    
    function test_Deployment_RevertWhen_ProtocolFeeRateExceed100Percent() external {
        ConfigManagerDataTypes.InitConfigManagerParams memory data = ConfigManagerDataTypes.InitConfigManagerParams(
            maxTotalSupplyAllowed,
            1.1e4, //110%
            insuranceRate,
            minTicketSalesDuration,
            maxTicketSalesDuration
        );
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        configManager = new ConfigManager(implementationManager, data);
    }

    function test_Deployment_RevertWhen_InsuranceRateExceed100Percent() external {
        ConfigManagerDataTypes.InitConfigManagerParams memory data = ConfigManagerDataTypes.InitConfigManagerParams(
            maxTotalSupplyAllowed,
            protocolFeeRate,
            1.1e4, //110%
            minTicketSalesDuration,
            maxTicketSalesDuration
        );
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        configManager = new ConfigManager(implementationManager, data);
    }

    function test_Deployment_RevertWhen_MinDurationHigherThanMaxOne() external {
        ConfigManagerDataTypes.InitConfigManagerParams memory data = ConfigManagerDataTypes.InitConfigManagerParams(
            maxTotalSupplyAllowed,
            protocolFeeRate,
            insuranceRate,
            maxTicketSalesDuration + 1,
            maxTicketSalesDuration
        );
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        configManager = new ConfigManager(implementationManager, data);
    }

    function test_Deployment_RevertWhen_MaxSupplyAllowedIsZero() external {
        ConfigManagerDataTypes.InitConfigManagerParams memory data = ConfigManagerDataTypes.InitConfigManagerParams(
            0,
            protocolFeeRate,
            insuranceRate,
            minTicketSalesDuration,
            maxTicketSalesDuration
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        configManager = new ConfigManager(implementationManager, data);
    }
    
    function test_SetprotocolFeeRate() external{
        changePrank(maintainer);
        uint16 newprotocolFeeRate = 2.5e2; //2.5%
        configManager.setProtocolFeeRate(newprotocolFeeRate);
        assertEq(configManager.protocolFeeRate(), newprotocolFeeRate);
    }

    function test_SetprotocolFeeRate_RevertWhen_ValueExceed100Percent() external{
        changePrank(maintainer);
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        configManager.setProtocolFeeRate( 1.1e4); //110%
    }

  function test_SetprotocolFeeRate_RevertWhen_NotMaintainerCalling() external{
        changePrank(alice);
        uint16 newprotocolFeeRate = 2.5e2; //2.5%
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setProtocolFeeRate(newprotocolFeeRate);
    }

    function test_setInsuranceRate() external{
        changePrank(maintainer);
        uint16 newInsuranceRate = 2.5e2; //2.5%
        configManager.setInsuranceRate(newInsuranceRate);
        assertEq(configManager.insuranceRate(), newInsuranceRate);
    }

    function test_setInsuranceRate_RevertWhen_ValueExceed100Percent() external{
        changePrank(maintainer);
        uint16 newInsuranceRate = 1.1e4; //110%
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        configManager.setInsuranceRate(newInsuranceRate);
    }

  function test_setInsuranceRate_RevertWhen_NotMaintainerCalling() external{
        changePrank(alice);
        uint16 newInsuranceRate = 2.5e2; //2.5%
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setInsuranceRate(newInsuranceRate);
    }

  
    function test_SetMinTicketSalesDuration() external{
        changePrank(maintainer);
        uint64 newMinTicketSalesDuration = 1 weeks;
        configManager.setMinTicketSalesDuration(newMinTicketSalesDuration);
        assertEq(configManager.minTicketSalesDuration(), newMinTicketSalesDuration);
    }

    function test_SetMinTicketSalesDuration_RevertWhen_NotMaintainerCalling() external{
        changePrank(alice);
        uint64 newMinTicketSalesDuration = 1 weeks;
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setMinTicketSalesDuration(newMinTicketSalesDuration);
    }

    function test_SetMinTicketSalesDuration_RevertWhen_ValueIsHigherThanMaxDuration() external{
        changePrank(maintainer);
        uint64 newMinTicketSalesDuration = maxTicketSalesDuration * 2;
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        configManager.setMinTicketSalesDuration(newMinTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration() external{
        changePrank(maintainer);
        uint64 newMaxTicketSalesDuration = maxTicketSalesDuration + 1;
        configManager.setMaxTicketSalesDuration(newMaxTicketSalesDuration);
        assertEq(configManager.maxTicketSalesDuration(), newMaxTicketSalesDuration);
    }

    function test_SetMaxTicketSalesDuration_RevertWhen_NotMaintainerCalling() external{
        changePrank(alice);
        uint64 newMaxTicketSalesDuration = maxTicketSalesDuration + 1;
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setMaxTicketSalesDuration(newMaxTicketSalesDuration);
    }

    function testSetMaxTicketSalesDuration_RevertWhen_ValueIsLowerThanMinDuration() external{
        changePrank(maintainer);
        uint64 newMaxTicketSalesDuration = minTicketSalesDuration - 1;
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        configManager.setMaxTicketSalesDuration(newMaxTicketSalesDuration);
    }

    function test_SetMaxTicketSupplyAllowed() external{
        changePrank(maintainer);
        uint16 newMaxTotalSupply = 20000;
        configManager.setMaxTotalSupplyAllowed(newMaxTotalSupply);
        assertEq(configManager.maxTotalSupplyAllowed(), newMaxTotalSupply);
    }

    function test_SetMaxTicketSupplyAllowed_RevertWhen_NotMaintainerCalling() external{
        changePrank(alice);
        uint16 newMaxTotalSupply = 20000;
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setMaxTotalSupplyAllowed(newMaxTotalSupply);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {ConfigManager} from "../../../src/core/ConfigManager.sol";

import {ConfiguratorInputTypes} from "../../../src/libraries/types/ConfiguratorInputTypes.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";


contract ConfigManagerTest is Test, SetupUsers {

    AccessController accessController;
    ImplementationManager implementationManager;
    ConfigManager configManager;

    uint256 baseFeePercentage = 1e2; // 1%
    uint256 baseMaxTicketSupplyAllowed = 10000; 
    uint256 baseMinTicketSaleDuration = 86400; // 1 days
    uint256 baseMaxTicketSaleDuration = 8 weeks; // 2 months

    function setUp() public virtual override {
        SetupUsers.setUp(); 
        changePrank(deployer);
        
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));

        ConfiguratorInputTypes.InitConfigManagerInput memory data = ConfiguratorInputTypes.InitConfigManagerInput(
            baseFeePercentage,
            baseMaxTicketSupplyAllowed,
            baseMinTicketSaleDuration,
            baseMaxTicketSaleDuration
        );
        configManager = new ConfigManager(implementationManager, data);

        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.ConfigManager,
              address(configManager)
        );
    }

    function test_CorrecltySetup() external {
        assertEq(address(configManager.implementationManager()), address(implementationManager));
        assertEq(implementationManager.getImplementationAddress(ImplementationInterfaceNames.ConfigManager), address(configManager));
        assertEq(configManager.procolFeesPercentage(), baseFeePercentage);
        assertEq(configManager.minTicketSalesDuration(), baseMinTicketSaleDuration);
        assertEq(configManager.maxTicketSalesDuration(), baseMaxTicketSaleDuration);
        assertEq(configManager.maxTicketSupplyAllowed(), baseMaxTicketSupplyAllowed);
        (uint256 min, uint256 max) = configManager.ticketSalesDurationLimits();
        assertEq(min, baseMinTicketSaleDuration);
        assertEq(max, baseMaxTicketSaleDuration);
    }
    
    function test_RevertIf_BasePercentageExceed100PercentOnDeployment() external {
        uint256 wrongBaseFeePercentage = 1.1e4; //110%
        ConfiguratorInputTypes.InitConfigManagerInput memory data = ConfiguratorInputTypes.InitConfigManagerInput(
            wrongBaseFeePercentage,
            baseMaxTicketSupplyAllowed,
            baseMinTicketSaleDuration,
            baseMaxTicketSaleDuration
        );
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        configManager = new ConfigManager(implementationManager, data);
    }

    function test_RevertIf_MinDurationHigherThanMaxOne() external {
        uint256 wrongMinDuration = baseMaxTicketSaleDuration * 2;
        ConfiguratorInputTypes.InitConfigManagerInput memory data = ConfiguratorInputTypes.InitConfigManagerInput(
            baseFeePercentage,
            baseMaxTicketSupplyAllowed,
            wrongMinDuration,
            baseMaxTicketSaleDuration
        );
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        configManager = new ConfigManager(implementationManager, data);
    }

    function test_RevertIf_MaxSupplyAllowedIsZero() external {
        
        ConfiguratorInputTypes.InitConfigManagerInput memory data = ConfiguratorInputTypes.InitConfigManagerInput(
            baseFeePercentage,
            0,
            baseMinTicketSaleDuration,
            baseMaxTicketSaleDuration
        );
        vm.expectRevert(Errors.CANT_BE_ZERO.selector);
        configManager = new ConfigManager(implementationManager, data);
    }
    
    function test_CorrectlySetFeePercentage() external{
        changePrank(maintainer);
        uint256 newFeePercentage = 2.5e2; //2.5%
        configManager.setProcolFeesPercentage(newFeePercentage);
        assertEq(configManager.procolFeesPercentage(), newFeePercentage);
    }

    function test_RevertIf_NewFeesPercentageExceed100Percent() external{
        changePrank(maintainer);
        uint256 newFeePercentage = 1.1e4; //110%
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        configManager.setProcolFeesPercentage(newFeePercentage);
    }

    function test_RevertIf_NotMaintainerUpdateFeePercentage() external{
        changePrank(alice);
        uint256 newFeePercentage = 2.5e2; //2.5%
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setProcolFeesPercentage(newFeePercentage);
    }

    function test_CorrectlySetMinTicketSalesDuration() external{
        changePrank(maintainer);
        uint256 newMinTicketSalesDuration = 1 weeks;
        configManager.setMinTicketSalesDuration(newMinTicketSalesDuration);
        assertEq(configManager.minTicketSalesDuration(), newMinTicketSalesDuration);
    }

    function test_RevertIf_NotMaintainerUpdateMinTicketSalesDuration() external{
        changePrank(alice);
        uint256 newMinTicketSalesDuration = 1 weeks;
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setMinTicketSalesDuration(newMinTicketSalesDuration);
    }

    function test_RevertIf_NewMinTicketSalesDurationIsHigherThanMaxDuration() external{
        changePrank(maintainer);
        uint256 newMinTicketSalesDuration = baseMaxTicketSaleDuration * 2;
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        configManager.setMinTicketSalesDuration(newMinTicketSalesDuration);
    }

    function test_CorrectlySetMaxTicketSalesDuration() external{
        changePrank(maintainer);
        uint256 newMaxTicketSalesDuration = baseMaxTicketSaleDuration * 2;
        configManager.setMaxTicketSalesDuration(newMaxTicketSalesDuration);
        assertEq(configManager.maxTicketSalesDuration(), newMaxTicketSalesDuration);
    }

    function test_RevertIf_NotMaintainerUpdateMaxTicketSalesDuration() external{
        changePrank(alice);
        uint256 newMaxTicketSalesDuration = baseMaxTicketSaleDuration * 2;
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setMaxTicketSalesDuration(newMaxTicketSalesDuration);
    }

    function test_RevertIf_NewMaxTicketSalesDurationIsLowerThanMinDuration() external{
        changePrank(maintainer);
        uint256 newMaxTicketSalesDuration = baseMinTicketSaleDuration - 10;
        vm.expectRevert(Errors.WRONG_DURATION_LIMITS.selector);
        configManager.setMaxTicketSalesDuration(newMaxTicketSalesDuration);
    }

    function test_CorrectlySetMaxTicketSupplyAllowed() external{
        changePrank(maintainer);
        uint256 newMaxTicketSupplyAllowed = 20000;
        configManager.setMaxTicketSupplyAllowed(newMaxTicketSupplyAllowed);
        assertEq(configManager.maxTicketSupplyAllowed(), newMaxTicketSupplyAllowed);
    }

    function test_RevertIf_NotMaintainerUpdateMaxTicketSupplyAllowed() external{
        changePrank(alice);
         uint256 newMaxTicketSupplyAllowed = 20000;
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        configManager.setMaxTicketSupplyAllowed(newMaxTicketSupplyAllowed);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {ConfigManager} from "../../../src/core/ConfigManager.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";


contract ConfigManagerTest is Test, SetupUsers {

    AccessController accessController;
    ImplementationManager implementationManager;
    ConfigManager configManager;

    uint256 baseFeePercentage = 1e2; // 1%
    function setUp() public virtual override {
        SetupUsers.setUp(); 
        changePrank(deployer);
        
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));
        configManager = new ConfigManager(implementationManager, baseFeePercentage);

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
    }
    
    function test_RevertIf_BasePercentageExceed100PercentOnDeployment() external {
        uint256 newFeePercentage = 1.1e4; //110%
        vm.expectRevert(Errors.EXCEED_MAX_PERCENTAGE.selector);
        configManager = new ConfigManager(implementationManager, newFeePercentage);
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
}
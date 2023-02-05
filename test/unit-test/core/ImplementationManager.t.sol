// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {SetupUsers} from "../../utils/SetupUsers.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";


contract ImplementationManagerTest is Test, SetupUsers {
    AccessController public accessController;
    ImplementationManager public implementationManager;

    function setUp() public virtual override {
        SetupUsers.setUp();
        vm.prank(admin);
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));
    }

    function test_implementationCorrectlyInit() external{
        address _accessController = implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController);
        assertEq(_accessController, address(accessController));
    }

    function test_MaintainerCanChangeImplementationAddress() external{
        vm.prank(maintainer);
        implementationManager.changeImplementationAddress(ImplementationInterfaceNames.AccessController, admin);
        address _accessController = implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController);
        assertEq(_accessController, admin);
    }

    function test_RevertIf_NotMaintainerChangeImplementationAddress() external{
        vm.prank(admin);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        implementationManager.changeImplementationAddress(ImplementationInterfaceNames.AccessController, admin);
    }
    function test_RevertIf_ImplementationDoesNotExist() external{
        bytes32 wrongInterfaces = keccak256("wrongInterfaces");
        vm.expectRevert(Errors.IMPLEMENTATION_NOT_FOUND.selector);
        implementationManager.getImplementationAddress(wrongInterfaces);
    }
}
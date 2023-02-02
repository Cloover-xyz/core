// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {SetupUsers} from "@test/utils/SetupUsers.sol";

import {AccessController} from "@core/AccessController.sol";
import {ImplementationProvider} from "@core/ImplementationProvider.sol";

import {Errors} from "@libraries/helpers/Errors.sol";
import {ImplementationInterfaceName} from "@libraries/helpers/ImplementationInterfaceName.sol";


contract ImplementationProviderTest is Test, SetupUsers {
    AccessController public accessController;
    ImplementationProvider public implementationProvider;

    function setUp() public virtual override {
        SetupUsers.setUp();
        vm.prank(admin);
        accessController = new AccessController(maintainer);
        implementationProvider = new ImplementationProvider(address(accessController));
    }

    function test_implementationCorrectlyInit() external{
        address _accessController = implementationProvider.getImplementationAddress(ImplementationInterfaceName.AccessController);
        assertEq(_accessController, address(accessController));
    }

    function test_MaintainerCanChangeImplementationAddress() external{
        vm.prank(maintainer);
        implementationProvider.changeImplementationAddress(ImplementationInterfaceName.AccessController, admin);
        address _accessController = implementationProvider.getImplementationAddress(ImplementationInterfaceName.AccessController);
        assertEq(_accessController, admin);
    }

    function test_RevertIf_NotMaintainerChangeImplementationAddress() external{
        vm.prank(admin);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        implementationProvider.changeImplementationAddress(ImplementationInterfaceName.AccessController, admin);
    }
    function test_RevertIf_ImplementationDoesNotExist() external{
        bytes32 wrongInterfaces = keccak256("wrongInterfaces");
        vm.expectRevert(Errors.IMPLEMENTATION_NOT_FOUND.selector);
        implementationProvider.getImplementationAddress(wrongInterfaces);
    }
}
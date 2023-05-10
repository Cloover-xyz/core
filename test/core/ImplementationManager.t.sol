// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ImplementationManagerTest is IntegrationTest {

    function setUp() public virtual override {
        super.setUp();
    }

    function test_Initialized() external{
        assertEq(
            implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController),
            address(accessController)
        );
    }

    function test_ChangeImplementationAddress(address newImplementation) external{
        changePrank(address(maintainer));
        implementationManager.changeImplementationAddress(ImplementationInterfaceNames.AccessController, newImplementation);
        assertEq(
            implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController),
            newImplementation
        );
    }

    function test_ChangeImplementationAddress_RevertIf_NotMaintainer(address newImplementation) external{
        changePrank(address(admin));
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        implementationManager.changeImplementationAddress(ImplementationInterfaceNames.AccessController, newImplementation);
    }

    function test_GetImplementationAddress_RevertWhen_InterfaceNotExist(bytes32 interfaceName) external{
        _assumeNotExistingInterface(interfaceName);
        vm.expectRevert(Errors.IMPLEMENTATION_NOT_FOUND.selector);
        implementationManager.getImplementationAddress(interfaceName);
    }
}
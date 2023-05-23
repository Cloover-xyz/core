// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ImplementationManagerTest is IntegrationTest {
    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

    address newImplementation = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public virtual override {
        super.setUp();
        changePrank(maintainer);
    }

    function test_Initialized() external {
        assertEq(
            implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController),
            address(accessController)
        );
    }

    function test_ChangeImplementationAddress() external {
        emit InterfaceImplementationChanged(ImplementationInterfaceNames.AccessController, newImplementation);

        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.AccessController, newImplementation
        );
        assertEq(
            implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController),
            newImplementation
        );
    }

    function test_ChangeImplementationAddress_RevertIf_NotMaintainer() external {
        changePrank(hacker);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.AccessController, newImplementation
        );
    }

    function test_GetImplementationAddress_RevertWhen_InterfaceNotExist() external {
        bytes32 interfaceName = "NotExistingInterface";
        vm.expectRevert(Errors.IMPLEMENTATION_NOT_FOUND.selector);
        implementationManager.getImplementationAddress(interfaceName);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract ImplementationManagerTest is IntegrationTest {
    event InterfaceImplementationChanged(bytes32 indexed interfaceName, address indexed newImplementationAddress);

    function _assumeInterfaceNotExist(bytes32 interfaceName) internal pure {
        vm.assume(interfaceName != ImplementationInterfaceNames.AccessController);
        vm.assume(interfaceName != ImplementationInterfaceNames.RandomProvider);
        vm.assume(interfaceName != ImplementationInterfaceNames.NFTWhitelist);
        vm.assume(interfaceName != ImplementationInterfaceNames.TokenWhitelist);
        vm.assume(interfaceName != ImplementationInterfaceNames.ClooverRaffleFactory);
        vm.assume(interfaceName != ImplementationInterfaceNames.Treasury);
    }

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

    function test_ChangeImplementationAddress(address newImplementation) external {
        vm.expectEmit(true, true, true, true);
        emit InterfaceImplementationChanged(ImplementationInterfaceNames.AccessController, newImplementation);

        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.AccessController, newImplementation
        );
        assertEq(
            implementationManager.getImplementationAddress(ImplementationInterfaceNames.AccessController),
            newImplementation
        );
    }

    function test_ChangeImplementationAddress_RevertIf_NotMaintainer(address caller, address newImplementation)
        external
    {
        _assumeNotMaintainer(caller);
        changePrank(caller);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        implementationManager.changeImplementationAddress(
            ImplementationInterfaceNames.AccessController, newImplementation
        );
    }

    function test_GetImplementationAddress_RevertWhen_InterfaceNotExist(bytes32 interfaceName) external {
        _assumeInterfaceNotExist(interfaceName);
        console2.logBytes32(interfaceName);
        vm.expectRevert(Errors.IMPLEMENTATION_NOT_FOUND.selector);
        implementationManager.getImplementationAddress(interfaceName);
    }
}

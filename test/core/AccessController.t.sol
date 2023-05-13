// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "test/helpers/IntegrationTest.sol";

contract AccessControllerTest is IntegrationTest {
    function setUp() public override {
        super.setUp();
    }

    function test_Initialized() external {
        assertTrue(accessController.hasRole(accessController.DEFAULT_ADMIN_ROLE(), deployer));
        assertTrue(accessController.hasRole(accessController.MAINTAINER_ROLE(), maintainer));
    }
}

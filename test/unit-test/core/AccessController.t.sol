// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {SetupUsers} from "../../utils/SetupUsers.sol";

import {AccessController} from "../../../src/core/AccessController.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";


contract AccessControllerTest is Test, SetupUsers {
    AccessController public accessController;

    function test_AccessControllerCorrectlySetup() external {
        vm.startPrank(admin);
        accessController = new AccessController(maintainer);
        assertTrue(accessController.hasRole(accessController.DEFAULT_ADMIN_ROLE(), admin));
        assertTrue(accessController.hasRole(accessController.MAINTAINER_ROLE(), maintainer));
    }
}
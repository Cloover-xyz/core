// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";

import {Utils} from "@test/utils/Utils.sol";

contract SetupUsers is Test {
    Utils internal utils;
 

    address payable[] internal users;
    address internal admin;
    address internal maintainer;
    address internal alice;
    address internal bob;
    address internal carole;
    

    function setUp() public virtual{
        utils = new Utils();
        users = utils.createUsers(6);

        admin = users[0];
        vm.label(admin, "Admin");
        maintainer = users[1];
        vm.label(maintainer, "Maintainer");
        alice = users[2];
        vm.label(alice, "Alice");
        bob = users[3];
        vm.label(bob, "Bob");
        carole = users[4];
        vm.label(carole, "Carole");
    }
    
}
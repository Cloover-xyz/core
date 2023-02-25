// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Utils} from "./Utils.sol";

contract SetupUsers is Test {
    Utils internal utils;
 

    address payable[] internal users;
    address internal deployer;
    address internal admin;
    address internal maintainer;
    address internal alice;
    address internal bob;

    function setUp() public virtual{
        utils = new Utils();
        users = utils.createUsers(6);

        deployer = users[0];
        vm.label(deployer, "Deployer");
        admin = users[1];
        vm.label(admin, "Admin");
        maintainer = users[2];
        vm.label(maintainer, "Maintainer");
        alice = users[3];
        vm.label(alice, "Alice");
        bob = users[4];
        vm.label(bob, "Bob");
    
    }
    
}
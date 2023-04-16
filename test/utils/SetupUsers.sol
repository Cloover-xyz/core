// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {Utils} from "./Utils.sol";

contract SetupUsers is Test {
    Utils internal utils;
 
    address payable[] internal users;
    address internal deployer;
    address internal admin;
    address internal treasury;
    address internal maintainer;
    address internal alice;
    address internal bob;
    address internal carole;

    function setUp() public virtual{
        utils = new Utils();
        users = utils.createUsers(7);

        deployer = users[0];
        vm.label(deployer, "Deployer");
        admin = users[1];
        vm.label(admin, "Admin");
        treasury = users[2];
        vm.label(treasury, "Treasury");
        maintainer = users[3];
        vm.label(maintainer, "Maintainer");
        alice = users[4];
        vm.label(alice, "Alice");
        bob = users[5];
        vm.label(bob, "Bob");
        carole = users[6];
        vm.label(carole, "Carole");
    
    }
    
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";

import {Utils} from "./Utils.sol";

contract SetupUsers is Test {
    Utils internal utils;
 
    address payable[] internal users;
    address internal deployer;
    uint256 internal deployerPK;
    address internal admin;
    uint256 internal adminPK;
    address internal treasury;
    uint256 internal treasuryPK;
    address internal maintainer;
    uint256 internal maintainerPK;
    address internal alice;
    uint256 internal alicePK;
    address internal bob;
    uint256 internal bobPK;
    uint256 internal carolePK;
    address internal carole;

    function setUp() public virtual{
        utils = new Utils();
        users = utils.createUsers(7);

        deployer = users[0];
        deployerPK = 1;
        vm.label(deployer, "Deployer");
        admin = users[1];
        adminPK = 2;
        vm.label(admin, "Admin");
        treasury = users[2];
        treasuryPK = 3;
        vm.label(treasury, "Treasury");
        maintainer = users[3];
        maintainerPK = 4;
        vm.label(maintainer, "Maintainer");
        alice = users[4];
        alicePK = 5;
        vm.label(alice, "Alice");
        bob = users[5];
        bobPK = 6;
        vm.label(bob, "Bob");
        carole = users[6];
        carolePK = 7;
        vm.label(carole, "Carole");
    }
}
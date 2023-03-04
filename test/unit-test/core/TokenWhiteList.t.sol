// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {MockERC20} from "../../../src/mocks/MockERC20.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {TokenWhitelist} from "../../../src/core/TokenWhitelist.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";


contract TokenWhitelistTest is Test, SetupUsers {
    MockERC20 tokenA;
    MockERC20 tokenB;

    AccessController accessController;
    ImplementationManager implementationManager;
    TokenWhitelist tokenWhitelist;

    function setUp() public virtual override {
        SetupUsers.setUp();

        changePrank(deployer);
        tokenA = new MockERC20("Token A", "A", 18);
        tokenB = new MockERC20("Token B", "B", 18);
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));
        tokenWhitelist = new TokenWhitelist(implementationManager);
        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.TokenWhitelist,
              address(tokenWhitelist)
        );
       
    }

    function test_CorrecltySetup() external {
        assertEq(address(tokenWhitelist.implementationManager()), address(implementationManager));
    }

    function test_CorrectlyWhitelistAToken() external{
        tokenWhitelist.addToWhitelist(address(tokenA));
        assertTrue(tokenWhitelist.isWhitelisted(address(tokenA)));
    }
    
    function test_RevertIf_TokenAlreadyWhitelisted() external{
        tokenWhitelist.addToWhitelist(address(tokenA));
        vm.expectRevert(Errors.TOKEN_ALREADY_WHITELISTED.selector);
        tokenWhitelist.addToWhitelist(address(tokenA));
    }

    function test_RevertIf_NotMaintainerAddToWhitelist() external{
        changePrank(deployer);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        tokenWhitelist.addToWhitelist(address(tokenA));
    }

    function test_CorrectlyRemoveAToken() external{
        tokenWhitelist.addToWhitelist(address(tokenA));
        tokenWhitelist.removeFromWhitelist(address(tokenA));
        assertFalse(tokenWhitelist.isWhitelisted(address(tokenA)));
    }

    function test_RevertIf_RemoveTokenNotWhitelisted() external{
        vm.expectRevert(Errors.TOKEN_NOT_WHITELISTED.selector);
        tokenWhitelist.removeFromWhitelist(address(tokenA));
    }

    function test_RevertIf_NotMaintainerRemoveToWhitelist() external{
        tokenWhitelist.addToWhitelist(address(tokenA));
        changePrank(deployer);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        tokenWhitelist.removeFromWhitelist(address(tokenA));
    }

    function test_CorrecltyGetAllTokenWhitelisted() external {
        tokenWhitelist.addToWhitelist(address(tokenA));
        tokenWhitelist.addToWhitelist(address(tokenB));
        address[] memory whitelist = tokenWhitelist.getWhitelist();
        assertEq(whitelist.length, 2);
        assertEq(whitelist[0], address(tokenA));
        assertEq(whitelist[1], address(tokenB));
    }
}

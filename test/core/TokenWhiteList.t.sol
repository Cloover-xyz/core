// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC20WithPermitMock} from "test/mocks/ERC20WithPermitMock.sol";

import {AccessController} from "src/core/AccessController.sol";
import {ImplementationManager} from "src/core/ImplementationManager.sol";
import {TokenWhitelist} from "src/core/TokenWhitelist.sol";

import "test/helpers/IntegrationTest.sol";

contract TokenWhitelistTest is IntegrationTest {
    ERC20WithPermitMock tokenA;
    ERC20WithPermitMock tokenB;

    AccessController accessController;
    ImplementationManager implementationManager;
    TokenWhitelist tokenWhitelist;

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(address(deployer));
        tokenA = new ERC20WithPermitMock("Token A", "A", 18);
        tokenB = new ERC20WithPermitMock("Token B", "B", 18);
        accessController = new AccessController(address(maintainer));
        implementationManager = new ImplementationManager(address(accessController));
        tokenWhitelist = new TokenWhitelist(implementationManager);
        
        changePrank(address(maintainer));
        implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.TokenWhitelist,
              address(tokenWhitelist)
        );
       
    }

    function test_ContractInitialization() external {
        assertEq(address(tokenWhitelist.implementationManager()), address(implementationManager));
    }

    function test_AddToWhitelist() external{
        tokenWhitelist.addToWhitelist(address(tokenA));
        assertTrue(tokenWhitelist.isWhitelisted(address(tokenA)));
    }
    
    function test_AddToWhitelist_RevertWhen_TokenAlreadyWhitelisted() external{
        tokenWhitelist.addToWhitelist(address(tokenA));
        vm.expectRevert(Errors.ALREADY_WHITELISTED.selector);
        tokenWhitelist.addToWhitelist(address(tokenA));
    }

    function test_AddToWhitelist_RevertWhen_NotMaintainerCalling() external{
        changePrank(address(deployer));
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        tokenWhitelist.addToWhitelist(address(tokenA));
    }

    function test_RemoveFromWhitelist() external{
        tokenWhitelist.addToWhitelist(address(tokenA));
        tokenWhitelist.removeFromWhitelist(address(tokenA));
        assertFalse(tokenWhitelist.isWhitelisted(address(tokenA)));
    }

    function test_RemoveFromWhitelist_RevertWhen_TokenNotWhitelisted() external{
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        tokenWhitelist.removeFromWhitelist(address(tokenA));
    }

    function test_RemoveFromWhitelist_RevertWhen_NotMaintainerCalling() external{
        tokenWhitelist.addToWhitelist(address(tokenA));
        changePrank(address(deployer));
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        tokenWhitelist.removeFromWhitelist(address(tokenA));
    }

    function test_GetWhitelist() external {
        tokenWhitelist.addToWhitelist(address(tokenA));
        tokenWhitelist.addToWhitelist(address(tokenB));
        address[] memory whitelist = tokenWhitelist.getWhitelist();
        assertEq(whitelist.length, 2);
        assertEq(whitelist[0], address(tokenA));
        assertEq(whitelist[1], address(tokenB));
    }
}

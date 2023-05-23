// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC20WithPermitMock} from "test/mocks/ERC20WithPermitMock.sol";

import {AccessController} from "src/core/AccessController.sol";
import {ImplementationManager} from "src/core/ImplementationManager.sol";
import {TokenWhitelist} from "src/core/TokenWhitelist.sol";

import "test/helpers/IntegrationTest.sol";

contract TokenWhitelistTest is IntegrationTest {
    event AddedToWhitelist(address indexed addedToken);
    event RemovedFromWhitelist(address indexed removedToken);

    address erc20Contract;

    function setUp() public virtual override {
        super.setUp();

        _deployTokenWhitelist();
        erc20Contract = address(new ERC20WithPermitMock("new ERC20", "NERC20", 8));
        changePrank(maintainer);
    }

    function test_Initialized() external {
        assertEq(address(tokenWhitelist.implementationManager()), address(implementationManager));
    }

    function test_AddToWhitelist() external {
        vm.expectEmit(true, true, true, true);
        emit AddedToWhitelist(erc20Contract);

        tokenWhitelist.addToWhitelist(erc20Contract);
        assertTrue(tokenWhitelist.isWhitelisted(erc20Contract));
    }

    function test_AddToWhitelist_RevertWhen_CollectionAlreadyWhitelisted() external {
        tokenWhitelist.addToWhitelist(erc20Contract);
        vm.expectRevert(Errors.ALREADY_WHITELISTED.selector);
        tokenWhitelist.addToWhitelist(erc20Contract);
    }

    function test_AddToWhitelist_RevertWhen_NotMaintainerCalling() external {
        changePrank(hacker);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        tokenWhitelist.addToWhitelist(erc20Contract);
    }

    function test_RemoveFromWhitelist() external {
        tokenWhitelist.addToWhitelist(erc20Contract);

        vm.expectEmit(true, true, true, true);
        emit RemovedFromWhitelist(erc20Contract);
        tokenWhitelist.removeFromWhitelist(erc20Contract);
        assertFalse(tokenWhitelist.isWhitelisted(erc20Contract));
    }

    function test_RemoveFromWhitelist_RevertWhen_CollectionNotWhitelisted() external {
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        tokenWhitelist.removeFromWhitelist(erc20Contract);
    }

    function test_RemoveFromWhitelist_RevertWhen_NotMaintainerCalling() external {
        tokenWhitelist.addToWhitelist(erc20Contract);
        changePrank(hacker);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        tokenWhitelist.removeFromWhitelist(erc20Contract);
    }

    function test_GetWhitelist() external {
        address erc20Contract_2 = address(new ERC20WithPermitMock("new ERC20", "NERC20", 8));
        tokenWhitelist.addToWhitelist(erc20Contract);
        tokenWhitelist.addToWhitelist(erc20Contract_2);
        address[] memory whitelist = tokenWhitelist.getWhitelist();
        assertEq(whitelist.length, 2);
        assertEq(whitelist[0], erc20Contract);
        assertEq(whitelist[1], erc20Contract_2);
    }

    function test_AddressZeroIsNotWhitelisted() external {
        assertFalse(tokenWhitelist.isWhitelisted(address(0)));
    }
}

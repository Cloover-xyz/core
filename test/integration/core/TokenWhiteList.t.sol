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

    function setUp() public virtual override {
        super.setUp();

        _deployTokenWhitelist();

        changePrank(maintainer);
    }

    function test_Initialized() external {
        assertEq(address(tokenWhitelist.implementationManager()), address(implementationManager));
    }

    function test_AddToWhitelist(address erc20) external {
        vm.expectEmit(true, true, true, true);
        emit AddedToWhitelist(erc20);

        tokenWhitelist.addToWhitelist(erc20);
        assertTrue(tokenWhitelist.isWhitelisted(erc20));
    }

    function test_AddToWhitelist_RevertWhen_CollectionAlreadyWhitelisted(address erc20) external {
        tokenWhitelist.addToWhitelist(erc20);
        vm.expectRevert(Errors.ALREADY_WHITELISTED.selector);
        tokenWhitelist.addToWhitelist(erc20);
    }

    function test_AddToWhitelist_RevertWhen_NotMaintainerCalling(address erc20, address caller) external {
        _assumeNotMaintainer(caller);
        changePrank(caller);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        tokenWhitelist.addToWhitelist(erc20);
    }

    function test_RemoveFromWhitelist(address erc20) external {
        tokenWhitelist.addToWhitelist(erc20);

        vm.expectEmit(true, true, true, true);
        emit RemovedFromWhitelist(erc20);
        tokenWhitelist.removeFromWhitelist(erc20);
        assertFalse(tokenWhitelist.isWhitelisted(erc20));
    }

    function test_RemoveFromWhitelist_RevertWhen_CollectionNotWhitelisted(address erc20) external {
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        tokenWhitelist.removeFromWhitelist(erc20);
    }

    function test_RemoveFromWhitelist_RevertWhen_NotMaintainerCalling(address erc20, address caller) external {
        _assumeNotMaintainer(caller);
        tokenWhitelist.addToWhitelist(erc20);
        changePrank(caller);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        tokenWhitelist.removeFromWhitelist(erc20);
    }

    function test_GetWhitelist(address erc20, address erc20_2) external {
        vm.assume(erc20 != erc20_2);
        tokenWhitelist.addToWhitelist(erc20);
        tokenWhitelist.addToWhitelist(erc20_2);
        address[] memory whitelist = tokenWhitelist.getWhitelist();
        assertEq(whitelist.length, 2);
        assertEq(whitelist[0], erc20);
        assertEq(whitelist[1], erc20_2);
    }

    function test_AddressZeroIsNotWhitelisted() external {
        assertFalse(tokenWhitelist.isWhitelisted(address(0)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC721Mock} from "test/mocks/ERC721Mock.sol";

import {AccessController} from "src/core/AccessController.sol";
import {ImplementationManager} from "src/core/ImplementationManager.sol";
import {NFTWhitelist} from "src/core/NFTWhitelist.sol";

import "test/helpers/IntegrationTest.sol";

contract NFTWhitelistTest is IntegrationTest {
    event AddedToWhitelist(address indexed addedNftCollection, address indexed creator);
    event RemovedFromWhitelist(address indexed removedNftCollection);

    function setUp() public virtual override {
        super.setUp();
        changePrank(maintainer);
    }

    function test_Initialized() external {
        assertEq(address(nftWhitelist.implementationManager()), address(implementationManager));
    }

    function test_AddToWhitelist(address erc721, address creator) external {
        vm.expectEmit(true, true, true, true);
        emit AddedToWhitelist(erc721, creator);

        nftWhitelist.addToWhitelist(erc721, creator);
        assertTrue(nftWhitelist.isWhitelisted(erc721));
        assertEq(nftWhitelist.getCollectionCreator(erc721), creator);
    }

    function test_AddToWhitelist_RevertWhen_CollectionAlreadyWhitelisted(address erc721, address creator) external {
        nftWhitelist.addToWhitelist(erc721, creator);
        vm.expectRevert(Errors.ALREADY_WHITELISTED.selector);
        nftWhitelist.addToWhitelist(erc721, creator);
    }

    function test_AddToWhitelist_RevertWhen_NotMaintainerCalling(address erc721, address caller, address creator)
        external
    {
        _assumeNotMaintainer(caller);
        changePrank(caller);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        nftWhitelist.addToWhitelist(erc721, creator);
    }

    function test_RemoveFromWhitelist(address erc721, address creator) external {
        nftWhitelist.addToWhitelist(erc721, creator);

        vm.expectEmit(true, true, true, true);
        emit RemovedFromWhitelist(erc721);
        nftWhitelist.removeFromWhitelist(erc721);
        assertFalse(nftWhitelist.isWhitelisted(erc721));
        assertEq(nftWhitelist.getCollectionCreator(erc721), address(0));
    }

    function test_RemoveFromWhitelist_RevertWhen_CollectionNotWhitelisted(address erc721) external {
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        nftWhitelist.removeFromWhitelist(erc721);
    }

    function test_RemoveFromWhitelist_RevertWhen_NotMaintainerCalling(address erc721, address caller, address creator)
        external
    {
        _assumeNotMaintainer(caller);
        nftWhitelist.addToWhitelist(erc721, creator);
        changePrank(caller);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        nftWhitelist.removeFromWhitelist(erc721);
    }

    function test_GetWhitelist(address erc721, address creator, address erc721_2, address creator2) external {
        vm.assume(erc721 != erc721_2);
        nftWhitelist.addToWhitelist(erc721, creator);
        nftWhitelist.addToWhitelist(erc721_2, creator2);
        address[] memory whitelist = nftWhitelist.getWhitelist();
        assertEq(whitelist.length, 2);
        assertEq(whitelist[0], erc721);
        assertEq(whitelist[1], erc721_2);
    }
}

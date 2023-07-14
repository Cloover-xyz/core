// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC721Mock} from "test/mocks/ERC721Mock.sol";

import {AccessController} from "src/core/AccessController.sol";
import {ImplementationManager} from "src/core/ImplementationManager.sol";
import {NFTWhitelist} from "src/core/NFTWhitelist.sol";

import "test/helpers/IntegrationTest.sol";

contract NFTWhitelistTest is IntegrationTest {
    event AddedToWhitelist(address indexed addedNftCollection, address indexed creator);
    event RemovedFromWhitelist(address indexed removedNftCollection);

    address newCollectionCreator = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address erc721Contract;

    function setUp() public virtual override {
        super.setUp();

        _deployNFTWhitelist();
        erc721Contract = address(new ERC721Mock("new NFT", "NNFT"));
        changePrank(maintainer);
    }

    function test_Initialized() external {
        assertEq(address(nftWhitelist.implementationManager()), address(implementationManager));
    }

    function test_AddToWhitelist() external {
        vm.expectEmit(true, true, true, true);
        emit AddedToWhitelist(erc721Contract, newCollectionCreator);

        nftWhitelist.addToWhitelist(erc721Contract, newCollectionCreator);
        assertTrue(nftWhitelist.isWhitelisted(erc721Contract));
        assertEq(nftWhitelist.getCollectionRoyaltiesRecipient(erc721Contract), newCollectionCreator);
    }

    function test_AddToWhitelist_RevertWhen_CollectionAlreadyWhitelisted() external {
        nftWhitelist.addToWhitelist(erc721Contract, newCollectionCreator);
        vm.expectRevert(Errors.ALREADY_WHITELISTED.selector);
        nftWhitelist.addToWhitelist(address(erc721Contract), creator);
    }

    function test_AddToWhitelist_RevertWhen_NotMaintainerCalling() external {
        changePrank(hacker);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        nftWhitelist.addToWhitelist(erc721Contract, newCollectionCreator);
    }

    function test_RemoveFromWhitelist() external {
        nftWhitelist.addToWhitelist(erc721Contract, newCollectionCreator);

        vm.expectEmit(true, true, true, true);
        emit RemovedFromWhitelist(erc721Contract);
        nftWhitelist.removeFromWhitelist(erc721Contract);
        assertFalse(nftWhitelist.isWhitelisted(erc721Contract));
        assertEq(nftWhitelist.getCollectionRoyaltiesRecipient(erc721Contract), address(0));
    }

    function test_RemoveFromWhitelist_RevertWhen_CollectionNotWhitelisted() external {
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        nftWhitelist.removeFromWhitelist(erc721Contract);
    }

    function test_RemoveFromWhitelist_RevertWhen_NotMaintainerCalling() external {
        nftWhitelist.addToWhitelist(erc721Contract, newCollectionCreator);
        changePrank(hacker);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        nftWhitelist.removeFromWhitelist(erc721Contract);
    }

    function test_GetWhitelist() external {
        address erc721Contract_2 = address(new ERC721Mock("new NFT 2", "NNFT"));

        nftWhitelist.addToWhitelist(erc721Contract, newCollectionCreator);
        nftWhitelist.addToWhitelist(erc721Contract_2, newCollectionCreator);

        address[] memory whitelist = nftWhitelist.getWhitelist();
        assertEq(whitelist.length, 2);
        assertEq(whitelist[0], erc721Contract);
        assertEq(whitelist[1], erc721Contract_2);
    }

    function test_AddressZeroIsNotWhitelisted() external {
        assertFalse(nftWhitelist.isWhitelisted(address(0)));
    }
}

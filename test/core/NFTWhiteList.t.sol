// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;


import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC721Mock} from "test/mocks/ERC721Mock.sol";

import {AccessController} from "src/core/AccessController.sol";
import {ImplementationManager} from "src/core/ImplementationManager.sol";
import {NFTWhitelist} from "src/core/NFTWhitelist.sol";

import "test/helpers/IntegrationTest.sol";

contract NFTWhitelistTest is IntegrationTest {
    

    function setUp() public virtual override {
        super.setUp();
    }

    function test_Initialized() external {
        assertEq(address(nftWhitelist.implementationManager()), address(implementationManager));
    }

    function test_AddToWhitelist() external{
        nftWhitelist.addToWhitelist(address(erc721Mock), address(creator));
        assertTrue(nftWhitelist.isWhitelisted(address(erc721Mock)));
        assertEq(nftWhitelist.getCollectionCreator(address(erc721Mock)), address(creator));
    }
    
    function test_AddToWhitelist_RevertWhen_CollectionAlreadyWhitelisted() external{
        nftWhitelist.addToWhitelist(address(erc721Mock), address(creator));
        vm.expectRevert(Errors.ALREADY_WHITELISTED.selector);
        nftWhitelist.addToWhitelist(address(erc721Mock), address(creator));
    }

    function test_AddToWhitelist_RevertWhen_NotMaintainerCalling() external{
        changePrank(address(deployer));
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        nftWhitelist.addToWhitelist(address(erc721Mock), address(creator));
    }

    function test_RemoveFromWhitelist() external{
        nftWhitelist.addToWhitelist(address(erc721Mock), address(creator));
        nftWhitelist.removeFromWhitelist(address(erc721Mock));
        assertFalse(nftWhitelist.isWhitelisted(address(erc721Mock)));
        assertEq(nftWhitelist.getCollectionCreator(address(erc721Mock)), address(0));
    }

    function test_RemoveFromWhitelist_RevertWhen_CollectionNotWhitelisted() external{
        vm.expectRevert(Errors.NOT_WHITELISTED.selector);
        nftWhitelist.removeFromWhitelist(address(erc721Mock));
    }

    function test_RemoveFromWhitelist_RevertWhen_NotMaintainerCalling() external{
        nftWhitelist.addToWhitelist(address(erc721Mock), address(creator));
        changePrank(address(deployer));
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        nftWhitelist.removeFromWhitelist(address(erc721Mock));
    }

    function test_GetWhitelist() external {
        IERC721 newNFTCollection = new ERC721Mock("Collection B", "NFT B");
        nftWhitelist.addToWhitelist(address(erc721Mock), address(creator));
        nftWhitelist.addToWhitelist(address(newNFTCollection), address(participant1));
        address[] memory whitelist = nftWhitelist.getWhitelist();
        assertEq(whitelist.length, 2);
        assertEq(whitelist[0], address(erc721Mock));
        assertEq(whitelist[1], address(newNFTCollection));
    }
}

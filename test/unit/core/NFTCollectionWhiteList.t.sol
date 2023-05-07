// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {MockERC721} from "../../mocks/MockERC721.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {NFTCollectionWhitelist} from "../../../src/core/NFTCollectionWhitelist.sol";

import {Errors} from "../../../src/libraries/helpers/Errors.sol";
import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";


contract NFTCollectionWhitelistTest is Test, SetupUsers {
    MockERC721 nftA;
    MockERC721 nftB;

    AccessController accessController;
    ImplementationManager implementationManager;
    NFTCollectionWhitelist nftCollectionWhitelist;

    function setUp() public virtual override {
        SetupUsers.setUp();

        vm.startPrank(deployer);
        nftA = new MockERC721("Collection A", "NFT A");
        nftB = new MockERC721("Collection B", "NFT B");
        accessController = new AccessController(maintainer);
        implementationManager = new ImplementationManager(address(accessController));
        nftCollectionWhitelist = new NFTCollectionWhitelist(implementationManager);
        changePrank(maintainer);
        implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.NFTWhitelist,
              address(nftCollectionWhitelist)
        );
       
    }

    function test_ContractInitialization() external {
        assertEq(address(nftCollectionWhitelist.implementationManager()), address(implementationManager));
    }

    function test_AddToWhitelist() external{
        nftCollectionWhitelist.addToWhitelist(address(nftA), alice);
        assertTrue(nftCollectionWhitelist.isWhitelisted(address(nftA)));
        assertEq(nftCollectionWhitelist.getCollectionCreator(address(nftA)), alice);
    }
    
    function test_AddToWhitelist_RevertWhen_CollectionAlreadyWhitelisted() external{
        nftCollectionWhitelist.addToWhitelist(address(nftA), alice);
        vm.expectRevert(Errors.COLLECTION_ALREADY_WHITELISTED.selector);
        nftCollectionWhitelist.addToWhitelist(address(nftA), alice);
    }

    function test_AddToWhitelist_RevertWhen_NotMaintainerCalling() external{
        changePrank(deployer);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        nftCollectionWhitelist.addToWhitelist(address(nftA), alice);
    }

    function test_RemoveFromWhitelist() external{
        nftCollectionWhitelist.addToWhitelist(address(nftA), alice);
        nftCollectionWhitelist.removeFromWhitelist(address(nftA));
        assertFalse(nftCollectionWhitelist.isWhitelisted(address(nftA)));
        assertEq(nftCollectionWhitelist.getCollectionCreator(address(nftA)), address(0));
    }

    function test_RemoveFromWhitelist_RevertWhen_CollectionNotWhitelisted() external{
        vm.expectRevert(Errors.COLLECTION_NOT_WHITELISTED.selector);
        nftCollectionWhitelist.removeFromWhitelist(address(nftA));
    }

    function test_RemoveFromWhitelist_RevertWhen_NotMaintainerCalling() external{
        nftCollectionWhitelist.addToWhitelist(address(nftA), alice);
        changePrank(deployer);
        vm.expectRevert(Errors.NOT_MAINTAINER.selector);
        nftCollectionWhitelist.removeFromWhitelist(address(nftA));
    }

    function test_GetWhitelist() external {
        nftCollectionWhitelist.addToWhitelist(address(nftA), alice);
        nftCollectionWhitelist.addToWhitelist(address(nftB), bob);
        address[] memory whitelist = nftCollectionWhitelist.getWhitelist();
        assertEq(whitelist.length, 2);
        assertEq(whitelist[0], address(nftA));
        assertEq(whitelist[1], address(nftB));
    }
}

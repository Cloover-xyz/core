// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Test} from "forge-std/Test.sol";

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {MockERC20} from "../../../src/mocks/MockERC20.sol";
import {MockERC721} from "../../../src/mocks/MockERC721.sol";

import {AccessController} from "../../../src/core/AccessController.sol";
import {ImplementationManager} from "../../../src/core/ImplementationManager.sol";
import {Raffle} from "../../../src/raffle/Raffle.sol";
import {RaffleFactory} from "../../../src/raffle/RaffleFactory.sol";
import {RaffleDataTypes} from "../../../src/raffle/RaffleDataTypes.sol";

import {ImplementationInterfaceNames} from "../../../src/libraries/helpers/ImplementationInterfaceNames.sol";

import {SetupUsers} from "../../utils/SetupUsers.sol";

contract RaffleTest is Test, SetupUsers {

 MockERC20  mockERC20;
    MockERC721 mockERC721;

    RaffleFactory factory;
    Raffle raffle;
    ImplementationManager implementationManager;
    AccessController accessController;
    
    uint256 maxTicketSupply = 10;
    uint256 nftId = 1;
    uint256 ticketPrice = 1e7; // 10
    uint64 openTicketSaleDuration = 24*60*60;
    
    function setUp() public virtual override {
       SetupUsers.setUp();

       mockERC20 = new MockERC20("Mocked USDC", "USDC", 6);
       mockERC20.mint(bob, 100e6);
       mockERC721 = new MockERC721("Mocked NFT", "NFT");
       mockERC721.mint(alice, nftId);
       
       changePrank(deployer);
       accessController = new AccessController(maintainer);
       implementationManager = new ImplementationManager(address(accessController));
       
       factory = new RaffleFactory(address(implementationManager));
      
       changePrank(maintainer);
       implementationManager.changeImplementationAddress(
              ImplementationInterfaceNames.RaffleFactory,
              address(factory)
       );
    }

    function test_RaffleCorrecltyInitialize() external {

    }

}
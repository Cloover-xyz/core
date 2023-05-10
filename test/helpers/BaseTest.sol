// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";
import {UserMock} from "test/mocks/UserMock.sol";

import {ImplementationInterfaceNames} from "src/libraries/ImplementationInterfaceNames.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";

import {stdStorage, StdStorage} from "@forge-std/StdStorage.sol";
import {console2} from "@forge-std/console2.sol";
import {console} from "@forge-std/console.sol";
import {Test} from "@forge-std/Test.sol";

contract BaseTest is Test {
    uint256 internal constant BLOCK_TIME = 12;

    uint256 private constant MAX_AMOUNT = 1e20 ether;
    uint256 constant INITIAL_BALANCE = 100 ether;

    UserMock internal deployer;
    UserMock internal admin;
    UserMock internal treasury;
    UserMock internal maintainer;
    UserMock internal collectionCreator;
    UserMock internal creator;
    UserMock internal participant1;
    UserMock internal participant2;

    function setUp() public virtual{
        
        deployer = _initUser(1);
        admin = _initUser(2);
        treasury = _initUser(3);
        maintainer = _initUser(4);
        collectionCreator = _initUser(5);
        creator = _initUser(6);
        participant1 = _initUser(7);
        participant2 = _initUser(8);

        _label();
    }

    function _label() internal {
        vm.label(address(deployer), "Deployer");
        vm.label(address(admin), "Admin");
        vm.label(address(treasury), "Treasury");
        vm.label(address(maintainer), "Maintainer");
        vm.label(address(collectionCreator), "CollectionCreator");
        vm.label(address(creator), "Creator");
        vm.label(address(participant1), "Participant1");
        vm.label(address(participant2), "Participant2");
    }

    function _setEthBalances(address user, uint256 balance) internal {
        vm.deal(user, balance);
    }

    function _setERC20Balances(address token, address user, uint256 balance) internal {
        deal(token, user, balance / (10 ** (18 - ERC20(token).decimals())));
    }

    function _initUser(uint256 privateKey) internal returns (UserMock newUser) {
        newUser = new UserMock(privateKey);
        _setEthBalances(address(newUser), INITIAL_BALANCE);
    }

    /// @dev Rolls & warps the given number of blocks forward the blockchain.
    function _forward(uint256 blocks) internal {
        vm.roll(block.number + blocks);
        vm.warp(block.timestamp + blocks * BLOCK_TIME); // Block speed should depend on test network.
    }

    /// @dev Rolls & warps the given number of time forward the blockchain.
    function _forwardByTimestamp(uint256 timestamp) external {
         vm.warp(uint64(block.timestamp) + timestamp);
         vm.roll(block.number + timestamp / BLOCK_TIME);
    }

    /// @dev Bounds the fuzzing input to a realistic number of blocks.
    function _boundBlocks(uint256 blocks) internal view returns (uint256) {
        return bound(blocks, 1, type(uint24).max);
    }

       /// @dev Bounds the fuzzing input to a realistic amount.
    function _boundAmount(uint256 amount) internal view virtual returns (uint256) {
        return bound(amount, 0, MAX_AMOUNT);
    }

    /// @dev Bounds the fuzzing input to a realistic amount.
    function _boundAmountNotZero(uint256 amount) internal view virtual returns (uint256) {
        return bound(amount, 1, MAX_AMOUNT);
    }

    /// @dev Bounds the fuzzing input to a non-zero 256 bits unsigned integer.
    function _boundNotZero(uint256 input) internal view virtual returns (uint256) {
        return bound(input, 1, type(uint256).max);
    }

    /// @dev Bounds the fuzzing input to a non-zero address.
    function _boundAddressNotZero(address input) internal view virtual returns (address) {
        return address(uint160(bound(uint256(uint160(input)), 1, type(uint160).max)));
    }

}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {SafeTransferLib, ERC20} from "@solmate/utils/SafeTransferLib.sol";

import {ImplementationInterfaceNames} from "src/libraries/ImplementationInterfaceNames.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PercentageMath} from "src/libraries/PercentageMath.sol";

import {stdStorage, StdStorage} from "@forge-std/StdStorage.sol";
import {console2} from "@forge-std/console2.sol";
import {console} from "@forge-std/console.sol";
import {Test} from "@forge-std/Test.sol";

contract BaseTest is Test {
    uint256 internal constant BLOCK_TIME = 12;

    uint256 internal constant MAX_AMOUNT = 10e18;

    /// @dev Rolls & warps the given number of blocks forward the blockchain.
    function _forward(uint256 blocks) internal {
        vm.roll(block.number + blocks);
        vm.warp(block.timestamp + blocks * BLOCK_TIME); // Block speed should depend on test network.
    }

    /// @dev Rolls & warps the given number of time forward the blockchain.
    function _forwardByTimestamp(uint64 timestamp) internal {
        vm.warp(uint64(block.timestamp) + timestamp);
        vm.roll(block.number + timestamp / BLOCK_TIME);
    }

    function _setBlockTimestamp(uint64 timestamp) internal {
        vm.warp(timestamp);
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

    function _boundAmountNotZeroUnderOf(uint256 input, uint256 max) internal view virtual returns (uint256) {
        return bound(input, 1, max);
    }

    /// @dev Bounds the fuzzing input to a number between min defined to max uint16.
    function _boundUint16AmountAboveOf(uint16 input, uint16 min) internal view virtual returns (uint16) {
        return uint16(bound(input, min, type(uint16).max));
    }

    /// @dev Bounds the fuzzing input to a number between 0 to max defined.
    function _boundAmountUnderOf(uint256 input, uint256 max) internal view virtual returns (uint256) {
        return bound(input, 0, max);
    }

    /// @dev Bounds the fuzzing input to a non-zero address.
    function _boundAddressNotZero(address input) internal view virtual returns (address) {
        return address(uint160(bound(uint256(uint160(input)), 1, type(uint160).max)));
    }

    /// @dev Bounds the fuzzing input to a realistic rate.
    function _boundPercentage(uint16 rate) internal view returns (uint16) {
        return uint16(bound(rate, 0, PercentageMath.PERCENTAGE_FACTOR));
    }

    /// @dev Bounds the fuzzing input to a realistic rate under max defined.
    function _boundPercentageUnderOf(uint16 rate, uint16 max) internal view returns (uint16) {
        return uint16(bound(rate, 0, max));
    }

    /// @dev Bounds the fuzzing input to a realistic rate under max defined.
    function _boundPercentageNotZeroUnderOf(uint16 rate, uint16 max) internal view returns (uint16) {
        return uint16(bound(rate, 1, max));
    }

    /// @dev Bounds the fuzzing input to a none realistic rate.
    function _boundPercentageExceed(uint16 rate) internal view returns (uint16) {
        return uint16(bound(rate, PercentageMath.PERCENTAGE_FACTOR + 1, type(uint16).max));
    }
}

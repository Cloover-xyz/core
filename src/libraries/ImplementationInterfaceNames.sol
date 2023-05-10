// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

/// @title ImplementationInterfaceNames
/// @author Cloover
/// @notice Library exposing interfaces names used in Cloover 
library ImplementationInterfaceNames {
  bytes32 public constant AccessController = 'AccessController';
  bytes32 public constant RandomProvider = 'RandomProvider';
  bytes32 public constant NFTWhitelist = 'NFTWhitelist';
  bytes32 public constant TokenWhitelist = 'TokenWhitelist';
  bytes32 public constant ClooverRaffleFactory = 'ClooverRaffleFactory';
  bytes32 public constant Treasury = 'Treasury';
}

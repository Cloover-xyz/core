// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract AccessController is AccessControl {
    
  bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MAINTAINER_ROLE, msg.sender);
  }
}
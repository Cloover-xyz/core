// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract AccessController is AccessControl {
  //----------------------------------------
  // Roles
  //----------------------------------------
  bytes32 public constant MAINTAINER_ROLE = keccak256("MAINTAINER_ROLE");

  //----------------------------------------
  // Initialization function
  //----------------------------------------
  constructor(address maintainer) {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MAINTAINER_ROLE, maintainer);
  }
}
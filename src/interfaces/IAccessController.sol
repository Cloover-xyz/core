// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IAccessController is IAccessControl {
  function MAINTAINER_ROLE() external view returns (bytes32);
  function MANAGER_ROLE() external view returns (bytes32);

}
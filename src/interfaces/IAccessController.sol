// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAccessControl} from "openzeppelin-contracts/contracts/access/IAccessControl.sol";

interface IAccessController is IAccessControl {
  function MAINTAINER_ROLE() external view returns (bytes32);
  function MANAGER_ROLE() external view returns (bytes32);

}
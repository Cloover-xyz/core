// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAccessController} from "@interfaces/IAccessController.sol";
import {IImplementationProvider} from "@interfaces/IImplementationProvider.sol";

import {ImplementationInterfaceName} from "@libraries/helpers/Constant.sol";
import {Errors} from "@libraries/helpers/Errors.sol";

contract ImplementationProvider is IImplementationProvider{

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
      bytes32 indexed interfaceName,
      address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
      IAccessController accessController = IAccessController(interfacesImplemented[ImplementationInterfaceName.AccessController]);
      if(!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
      _;
  }

  constructor(address _accessController) {
      interfacesImplemented[ImplementationInterfaceName.AccessController] = _accessController;
  }

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address implementationAddress)
  {
    implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
  }

}
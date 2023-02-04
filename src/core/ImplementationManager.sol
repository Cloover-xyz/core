// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IAccessController} from "@interfaces/IAccessController.sol";
import {IImplementationManager} from "@interfaces/IImplementationManager.sol";

import {ImplementationInterfaceNames} from "@libraries/helpers/ImplementationInterfaceNames.sol";
import {Errors} from "@libraries/helpers/Errors.sol";

contract ImplementationManager is IImplementationManager{

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
      IAccessController accessController = IAccessController(interfacesImplemented[ImplementationInterfaceNames.AccessController]);
      if(!accessController.hasRole(accessController.MAINTAINER_ROLE(), msg.sender)) revert Errors.NOT_MAINTAINER();
      _;
  }

  //----------------------------------------
  // Initialization function
  //----------------------------------------
  constructor(address _accessController) {
      interfacesImplemented[ImplementationInterfaceNames.AccessController] = _accessController;
  }

  //----------------------------------------
  // Externals functions
  //----------------------------------------
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
    if(implementationAddress == address(0x0)) revert Errors.IMPLEMENTATION_NOT_FOUND();
  }

}
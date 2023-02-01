// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {

  uint8 private decimals_;
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol) {
    decimals_ = _decimals;
  }

  function mint(address account, uint256 amount) public {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) public {
    _burn(account, amount);
  }

  function decimals() public view virtual override returns (uint8) {
        return decimals_;
  }
}
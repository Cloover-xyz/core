// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {}

  function mint(address to, uint256 tokenId) public {
    _safeMint(to, tokenId);
  }

}
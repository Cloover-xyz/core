// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {

  constructor(
    string memory _name,
    string memory _symbol
  ) ERC721(_name, _symbol) {}

  function mint(address to, uint256 tokenId) public {
    _safeMint(to, tokenId);
  }

}
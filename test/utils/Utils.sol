// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";

contract Utils is Test {
    uint256 constant INITIAL_BALANCE = 100 ether;

    // create users with 100 ETH balance each
    function createUsers(uint256 userNum)
        external
        returns (address payable[] memory)
    {
        address payable[] memory users = new address payable[](userNum);
        for (uint256 i = 0; i < userNum; i++) {
            address user = vm.addr(i+1);
            vm.deal(user, INITIAL_BALANCE);
            users[i] = payable(user);
        }
        return users;
    }

    // move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }

    function goForward(uint256 timestampToAdd) external {
         vm.warp(uint64(block.timestamp) + timestampToAdd);
    }
}
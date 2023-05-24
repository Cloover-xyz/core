// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {IRandomProvider} from "src/interfaces/IRandomProvider.sol";

import {RandomProviderTypes} from "src/libraries/Types.sol";

contract RaffleMock {
    uint256 public requestId;
    uint256[] public randomNumbers;

    function requestRandomNumbers(address randomProvider, uint32 numWords) external {
        requestId = IRandomProvider(randomProvider).requestRandomNumbers(numWords);
    }

    function draw(uint256[] memory randomWords) external {
        randomNumbers = randomWords;
    }

    function randomNumbersLenght() external view returns (uint256) {
        return randomNumbers.length;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IRandomProvider {

    /**
     * @notice Request a random numbers using ChainLinkVRFv2
     * @param numWords number of random number requested
     */
    function requestRandomNumbers(uint32 numWords) external;
}
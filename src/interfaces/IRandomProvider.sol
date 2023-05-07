// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

interface IRandomProvider {

    /**
     * @notice Request a random numbers using ChainLinkVRFv2
     * @param numWords number of random number requested
     * @return requestId return by ChainLink
     */
    function requestRandomNumbers(uint32 numWords) external returns(uint256 requestId);
}
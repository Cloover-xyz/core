// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {VRFConsumerBaseV2} from "@chainlink/v0.8/vrf/VRFConsumerBaseV2.sol";

contract VRFConsumerBaseV2Mock {
    mapping(address => uint256) public raffleToRequestId;
    mapping(uint256 => address) public requestIdToRaffle;
    mapping(uint256 => uint32) public requestIdToNumWords;
    uint256 internal nounce;

    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId) {
        nounce++;
        requestId = uint256(
            keccak256(
                abi.encode(keyHash, subId, minimumRequestConfirmations, callbackGasLimit, numWords, nounce, msg.sender)
            )
        );

        raffleToRequestId[msg.sender] = requestId;
        requestIdToRaffle[requestId] = msg.sender;
        requestIdToNumWords[requestId] = numWords;
    }

    function callingRawFulFillRandomWorks(address raffle) external {
        uint256 requestId = raffleToRequestId[raffle];
        uint256[] memory numWords = new uint256[](requestIdToNumWords[requestId]);
        for (uint256 i = 0; i < requestIdToNumWords[requestId]; i++) {
            numWords[i] = uint256(keccak256(abi.encode(blockhash(block.number - 1), numWords, requestId, msg.sender)));
        }

        VRFConsumerBaseV2(raffle).rawFulfillRandomWords(requestId, numWords);
    }
}

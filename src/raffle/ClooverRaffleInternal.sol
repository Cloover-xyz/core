// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {Errors} from "../libraries/helpers/Errors.sol";
import {ClooverRaffleDataTypes} from "../libraries/types/ClooverRaffleDataTypes.sol";

import {ClooverRaffleStorage} from "./ClooverRaffleStorage.sol";

/// @title ClooverRaffleInternal
/// @author Cloover
/// @notice Abstract contract exposing `Raffle`'s internal functions.
abstract contract ClooverRaffleInternal is ClooverRaffleStorage {
    
     /// @notice Searches a sorted `array` and returns the first index that contains the `ticketNumberToSearch`
     /// https://docs.openzeppelin.com/contracts/3.x/api/utils#Arrays-findUpperBound-uint256---uint256-
     /// @param array The array to be searched
     /// @param ticketNumberToSearch The ticket number to search for
     /// @return The first index that contains the `ticketNumberToSearch` 
    function findUpperBound(ClooverRaffleDataTypes.PurchasedEntries[] memory array, uint256 ticketNumberToSearch) internal pure returns (uint256) {
        if (array.length == 0) return 0;

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (array[mid].currentTicketsSold > ticketNumberToSearch) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        if (low > 0 && array[low - 1].currentTicketsSold == ticketNumberToSearch) {
            return low - 1;
        } else {
            return low;
        }
    }



    /// @notice Transfers ETH to the recipient address
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = payable(to).call{value: value}(new bytes(0));
        if (!success) revert Errors.TRANSFER_FAIL();
    }



}
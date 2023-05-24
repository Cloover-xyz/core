// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract RaffleFactoryMock {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _registeredRaffles;

    function removeClooverRaffleFromRegister(address raffle) external {
        _registeredRaffles.remove(raffle);
    }

    function addClooverRaffleToRegister(address raffle) external {
        _registeredRaffles.add(raffle);
    }

    function isRegistered(address raffle) external view returns (bool) {
        return _registeredRaffles.contains(raffle);
    }
}

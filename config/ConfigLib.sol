// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {stdJson} from "@forge-std/StdJson.sol";

struct Config {
    string json;
}

library ConfigLib {
    using stdJson for string;

    string internal constant RPC_ALIAS_PATH = "$.rpcAlias";
    string internal constant CLOOVER_MAINTAINER = "$.addressMaintainer";
    string internal constant ADDRESSES_IMPLEMENTATION_MANAGER_PATH = "$.inplementationManager";
    string internal constant ADDRESSES_ACCESSCONTROLLER_PATH = "$.accessController";

    function getAddress(Config storage config, string memory key) internal returns (address) {
        return config.json.readAddress(string.concat("$.", key));
    }

    function getAddressArray(Config storage config, string[] memory keys)
        internal
        returns (address[] memory addresses)
    {
        addresses = new address[](keys.length);

        for (uint256 i; i < keys.length; ++i) {
            addresses[i] = getAddress(config, keys[i]);
        }
    }

    function getRpcAlias(Config storage config) internal returns (string memory) {
        return config.json.readString(RPC_ALIAS_PATH);
    }

    function getMaintainerAddress(Config storage config) internal returns (address) {
        return config.json.readAddress(CLOOVER_MAINTAINER);
    }

    function getImplementationManagerAddresses(Config storage config) internal returns (address) {
        return config.json.readAddress(ADDRESSES_IMPLEMENTATION_MANAGER_PATH);
    }

    function getAccessControllerAddresses(Config storage config) internal returns (address) {
        return config.json.readAddress(ADDRESSES_ACCESSCONTROLLER_PATH);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {console2} from "@forge-std/console2.sol";
import {stdJson} from "@forge-std/StdJson.sol";

import {RandomProviderTypes, ClooverRaffleTypes} from "src/libraries/Types.sol";

struct Config {
    string json;
}

library ConfigLib {
    using stdJson for string;

    string internal constant RPC_ALIAS_PATH = "$.rpcAlias";
    string internal constant CLOOVER_MAINTAINER = "$.addressMaintainer";
    string internal constant ADDRESSES_IMPLEMENTATION_MANAGER_PATH = "$.inplementationManager";
    string internal constant ADDRESSES_ACCESSCONTROLLER_PATH = "$.accessController";
    string internal constant CHAINLINK_VRF_DATA_PATH = "$.chainLinkVRFData";
    string internal constant RAFFLE_FACTORY_CONFIG_PATH = "$.raffleFactoryConfig";

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

    function getChainlinkVRFData(Config storage config)
        internal
        returns (RandomProviderTypes.ChainlinkVRFData memory)
    {
        address vrfCoordinator = config.json.readAddress(string.concat(CHAINLINK_VRF_DATA_PATH, ".vrfCoordinator"));
        bytes32 keyHash = config.json.readBytes32(string.concat(CHAINLINK_VRF_DATA_PATH, ".keyHash"));
        uint32 callbackGasLimit =
            uint32(config.json.readUint(string.concat(CHAINLINK_VRF_DATA_PATH, ".callbackGasLimit")));
        uint16 requestConfirmations =
            uint16(config.json.readUint(string.concat(CHAINLINK_VRF_DATA_PATH, ".requestConfirmations")));
        uint64 subscriptionId = uint64(config.json.readUint(string.concat(CHAINLINK_VRF_DATA_PATH, ".subscriptionId")));

        return RandomProviderTypes.ChainlinkVRFData({
            vrfCoordinator: vrfCoordinator,
            keyHash: keyHash,
            callbackGasLimit: callbackGasLimit,
            requestConfirmations: requestConfirmations,
            subscriptionId: subscriptionId
        });
    }

    function getRaffleFactoryConfig(Config storage config)
        internal
        returns (ClooverRaffleTypes.FactoryConfigParams memory)
    {
        uint16 maxTicketSupplyAllowed =
            uint16(config.json.readUint(string.concat(RAFFLE_FACTORY_CONFIG_PATH, ".maxTicketSupplyAllowed")));
        uint16 protocolFeeRate =
            uint16(config.json.readUint(string.concat(RAFFLE_FACTORY_CONFIG_PATH, ".protocolFeeRate")));
        uint16 insuranceRate = uint16(config.json.readUint(string.concat(RAFFLE_FACTORY_CONFIG_PATH, ".insuranceRate")));
        uint16 minTicketSalesDuration =
            uint16(config.json.readUint(string.concat(RAFFLE_FACTORY_CONFIG_PATH, ".minTicketSalesDuration")));
        uint16 maxTicketSalesDuration =
            uint16(config.json.readUint(string.concat(RAFFLE_FACTORY_CONFIG_PATH, ".maxTicketSalesDuration")));

        return ClooverRaffleTypes.FactoryConfigParams({
            maxTicketSupplyAllowed: maxTicketSupplyAllowed,
            protocolFeeRate: protocolFeeRate,
            insuranceRate: insuranceRate,
            minTicketSalesDuration: minTicketSalesDuration,
            maxTicketSalesDuration: maxTicketSalesDuration
        });
    }
}

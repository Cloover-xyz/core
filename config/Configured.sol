// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import {Config, ConfigLib} from "config/ConfigLib.sol";

import {StdChains, VmSafe} from "@forge-std/StdChains.sol";

import {RandomProviderTypes, ClooverRaffleTypes} from "src/libraries/Types.sol";

contract Configured is StdChains {
    using ConfigLib for Config;

    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    Chain internal chain;
    Config internal config;

    string internal configFilePath;

    address internal maintainer;
    address internal implementationManager;
    address internal accessController;

    ClooverRaffleTypes.FactoryConfigParams internal factoryConfig;
    RandomProviderTypes.ChainlinkVRFData internal chainlinkVRFData;

    function _network() internal virtual returns (string memory) {
        Chain memory currentChain = getChain(block.chainid);
        return currentChain.chainAlias;
    }

    function _initConfig() internal returns (Config storage) {
        if (bytes(config.json).length == 0) {
            string memory root = vm.projectRoot();
            configFilePath = string.concat(root, "/config/", _network(), ".json");

            config.json = vm.readFile(configFilePath);
        }

        return config;
    }

    function _loadConfig() internal virtual {
        string memory rpcAlias = config.getRpcAlias();

        chain = getChain(rpcAlias);

        implementationManager = config.getImplementationManagerAddresses();
        accessController = config.getAccessControllerAddresses();
        maintainer = config.getMaintainerAddress();

        chainlinkVRFData = config.getChainlinkVRFData();
        factoryConfig = config.getRaffleFactoryConfig();
    }
}

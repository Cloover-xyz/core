// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@forge-std/Script.sol";

import {Configured, ConfigLib, Config} from "config/Configured.sol";

import {NFTWhitelist} from "src/core/NFTWhitelist.sol";

contract DeployNFTWhitelist is Script, Configured {
    using ConfigLib for Config;

    function run() external {
        _initConfig();
        _loadConfig();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        _deploy();

        vm.stopBroadcast();
    }

    function _deploy() internal {
        new NFTWhitelist(implementationManager);
    }
}

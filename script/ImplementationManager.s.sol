// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import {AccessController} from "src/core/AccessController.sol";

import {Configured, ConfigLib, Config} from "config/Configured.sol";

import "@forge-std/Script.sol";

contract DeployImplementationManager is Script, Configured {
    using ConfigLib for Config;

    function run() external {
        _initConfig();
        _loadConfig();

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        uint256 chainId = block.chainid;
        console2.log("chainId", chainId);

        Chain memory chain = getChain(chainId);
        console2.log("chain", chain.chainAlias);
        // _deploy();

        vm.stopBroadcast();
    }

    function _deploy() internal {
        new AccessController(maintainer);
    }
}

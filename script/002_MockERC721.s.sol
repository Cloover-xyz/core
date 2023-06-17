// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.19;

import "@forge-std/Script.sol";

import {Configured, ConfigLib, Config} from "config/Configured.sol";

import {ERC721Mock} from "test/mocks/ERC721Mock.sol";

contract DeployERC20WithPermitMock is Script, Configured {
    using ConfigLib for Config;

    function run() external {
        _initConfig();

        require(config.getIsTestnet());

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        _deploy();

        vm.stopBroadcast();
    }

    function _deploy() internal {
        new ERC721Mock('erc721Mock', 'ERC721_1');
    }
}

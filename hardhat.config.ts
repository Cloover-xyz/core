import "@nomicfoundation/hardhat-toolbox";
import "hardhat-preprocessor";
import "hardhat-deploy";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import { HardhatUserConfig } from "hardhat/config";
import { getRemappings } from "./utils/gitRemappings";
import { accounts, node_url, addForkConfiguration } from "./utils/network";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  namedAccounts: {
    deployer: 0,
    admin: 1,
    maintainer: 2,
  },

  networks: addForkConfiguration({
    hardhat: {
      initialBaseFeePerGas: 0, // to fix : https://github.com/sc-forks/solidity-coverage/issues/652, see https://github.com/sc-forks/solidity-coverage/issues/652#issuecomment-896330136
      tags: ["dev"],
    },
    localhost: {
      url: node_url("localhost"),
      accounts: accounts(),
      tags: ["dev"],
    },
    mainnet: {
      url: node_url("mainnet"),
      accounts: accounts("mainnet", true),
    },
    staging: {
      url: node_url("goerli"),
      accounts: accounts("goerli", true),
    },
    goerli: {
      url: node_url("goerli"),
      accounts: accounts("goerli", true),
    },
  }),
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_KEY!,
      goerli: process.env.ETHERSCAN_KEY!,
    },
  },
  paths: {
    sources: "./src", // Use ./src rather than ./contracts as Hardhat expects
    cache: "./cache_hardhat", // Use a different cache for Hardhat than Foundry
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
};

export default config;

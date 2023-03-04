import { DeployFunction } from "hardhat-deploy/types";
import { verifyContract } from "../utils/verifyContract";
import { networkConfig } from "../networkConfig";
import { addToImplementationManager } from "../utils/addToImplementationManager";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
  network,
}) {
  const { deploy } = deployments;
  const { deployer, maintainer } = await getNamedAccounts();
  const { configManager: configManagerData, blockConfirmations } =
    networkConfig[network.name];

  const ImplementationManager = await deployments.get("ImplementationManager");

  const args: unknown[] = [
    ImplementationManager.address,
    [
      configManagerData.baseFeePercentage,
      configManagerData.maxTicketSupplyAllowed,
      configManagerData.minSalesDuration,
      configManagerData.maxSalesDuration,
    ],
  ];

  const configManager = await deploy("ConfigManager", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: blockConfirmations || 1,
  });

  if (!network.tags.dev) {
    await verifyContract(configManager.address, args);
  }

  await addToImplementationManager(
    ImplementationManager.address,
    configManager.address,
    "ConfigManager",
    maintainer
  );
};
export default func;
func.tags = ["ConfigManager"];

import { DeployFunction } from "hardhat-deploy/types";
import { verifyContract } from "../utils/verifyContract";
import { networkConfig } from "../networkConfig";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
  network,
}) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const { blockConfirmations } = networkConfig[network.name];
  const AccessController = await deployments.get("AccessController");
  const args: unknown[] = [AccessController.address];

  const implementationManager = await deploy("ImplementationManager", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: blockConfirmations || 1,
  });
  if (!network.tags.dev) {
    await verifyContract(implementationManager.address, args);
  }
};
export default func;
func.tags = ["ImplementationManager"];

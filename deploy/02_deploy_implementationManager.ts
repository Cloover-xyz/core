import { DeployFunction } from "hardhat-deploy/types";
import { verifyContract } from "../utils/verifyContract";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
  network,
}) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const AccessController = await deployments.get("AccessController");
  const args: unknown[] = [AccessController.address];

  const implementationManager = await deploy("ImplementationManager", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: 2,
  });
  if (!network.tags.dev) {
    await verifyContract(implementationManager.address, args);
  }
};
export default func;
func.tags = ["ImplementationManager"];

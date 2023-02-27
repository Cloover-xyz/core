import { DeployFunction } from "hardhat-deploy/types";
import { verifyContract } from "../utils/verifyContract";
import { networkConfig } from "../networkConfig";

const func: DeployFunction = async function ({
  deployments,
  getNamedAccounts,
  network,
}) {
  const { deploy } = deployments;
  const { blockConfirmations } = networkConfig[network.name];
  const { deployer, maintainer } = await getNamedAccounts();

  const args: unknown[] = [maintainer];

  const accessController = await deploy("AccessController", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: blockConfirmations || 1,
  });
  if (!network.tags.dev) {
    await verifyContract(accessController.address, args);
  }
};
export default func;
func.tags = ["AccessController"];

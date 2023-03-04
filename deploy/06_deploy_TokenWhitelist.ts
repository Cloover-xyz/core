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
  const { blockConfirmations } = networkConfig[network.name];

  const ImplementationManager = await deployments.get("ImplementationManager");

  const args: unknown[] = [ImplementationManager.address];

  const tokenWhitelist = await deploy("TokenWhitelist", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: blockConfirmations || 1,
  });

  if (!network.tags.dev) {
    await verifyContract(tokenWhitelist.address, args);
  }

  await addToImplementationManager(
    ImplementationManager.address,
    tokenWhitelist.address,
    "TokenWhitelist",
    maintainer
  );
};
export default func;
func.tags = ["TokenWhitelist"];

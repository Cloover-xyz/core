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

  const NFTCollectionWhitelist = await deploy("NFTCollectionWhitelist", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: blockConfirmations || 1,
  });

  if (!network.tags.dev) {
    await verifyContract(NFTCollectionWhitelist.address, args);
  }

  await addToImplementationManager(
    ImplementationManager.address,
    NFTCollectionWhitelist.address,
    "NFTCollectionWhitelist",
    maintainer
  );
};
export default func;
func.tags = ["NFTCollectionWhitelist"];

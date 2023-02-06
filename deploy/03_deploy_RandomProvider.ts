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
  const { chainlink: chainlinkData, blockConfirmations } =
    networkConfig[network.name];

  const ImplementationManager = await deployments.get("ImplementationManager");

  const args: unknown[] = [
    ImplementationManager.address,
    [
      chainlinkData.VRFCoordinator,
      chainlinkData.keyHash,
      chainlinkData.callbackGasLimit,
      chainlinkData.requestConfirmations,
      chainlinkData.subscriptionId,
    ],
  ];

  const randomProvider = await deploy("RandomProvider", {
    from: deployer,
    args,
    log: true,
    waitConfirmations: blockConfirmations || 1,
  });

  if (!network.tags.dev) {
    await verifyContract(randomProvider.address, args);
  }

  await addToImplementationManager(
    ImplementationManager.address,
    randomProvider.address,
    "RandomProvider",
    maintainer
  );
};
export default func;
func.tags = ["RandomProvider"];

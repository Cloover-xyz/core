import { ethers } from "hardhat";
import { ImplementationManager } from "../typechain";

export const addDeployedContractToImplementationManager = async (
  implementationManagerAddress: string,
  deployedContractAddress: string,
  interfaceName: string,
  maintainer: string
) => {
  console.log("=".repeat(50));
  console.log(`adding ${interfaceName} contract to implementationManager`);
  try {
    const maintainerSigner = await ethers.getSigner(maintainer);
    const implementationManagerInstance = (await ethers.getContractAt(
      "ImplementationManager",
      implementationManagerAddress,
      maintainerSigner
    )) as unknown as ImplementationManager;
    await implementationManagerInstance.changeImplementationAddress(
      ethers.utils.formatBytes32String(interfaceName),
      deployedContractAddress
    );
    console.log(
      `${interfaceName} implementation correctly added to implementationManager`
    );
  } catch (error) {
    console.log(error);
  }
  console.log("=".repeat(50));
};

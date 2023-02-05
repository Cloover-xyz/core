import { run } from "hardhat";

export const verifyContract = async (
  contractAddress: string,
  args: unknown[],
  libraries?: Record<string, string>
) => {
  console.log("=".repeat(50));
  console.log("Trying to verify contract");

  try {
    await run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
      libraries,
    });
  } catch (error) {
    console.log(error);
  }
  console.log("=".repeat(50));
};

type NetworkConfig = {
  [network: string]: {
    chainlink: {
      LinkToken: string;
      VRFCoordinator: string;
      keyHash: string;
      callbackGasLimit: number;
      requestConfirmations: number;
      subscriptionId?: number;
    };
    blockConfirmations?: number;
  };
};

export const networkConfig: NetworkConfig = {
  goerli: {
    chainlink: {
      LinkToken: "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
      VRFCoordinator: "0x2ca8e0c643bde4c2e08ab1fa0da3401adad7734d",
      keyHash:
        "0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15",
      callbackGasLimit: 100000,
      requestConfirmations: 3,
      subscriptionId: Number(process.env.CHAINLINK_VRF_SUBSCRIPTION_ID),
    },
    blockConfirmations: 6,
  },
};

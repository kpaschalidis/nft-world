import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.6",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10_000,
      },
    },
  },
  networks: {
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: [process.env.WALLET_PRIVATE_KEY!].filter(Boolean),
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
      accounts: process.env.MNEMONIC
        ? { mnemonic: process.env.MNEMONIC }
        : [process.env.WALLET_PRIVATE_KEY!].filter(Boolean),
    },
    hardhat: {
      initialBaseFeePerGas: 0,
    },
  },
};

export default config;

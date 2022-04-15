import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import 'hardhat-docgen';
import 'hardhat-dependency-compiler';
import 'hardhat-gas-reporter';
import 'hardhat-spdx-license-identifier';
import 'solidity-coverage';

import Dotenv from 'dotenv';

Dotenv.config();

const {
  NODE_URL_MAINNET,
  NODE_URL_TESTNET,
  PKEY_MAINNET,
  PKEY_TESTNET,
  REPORT_GAS,
} = process.env;

export default {
  solidity: {
    compilers: [
      {
        version: '0.8.11',
      },
      {
        version: '0.7.0',
      },
    ],
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  networks: {
    hardhat: {
      forking: {
        url: 'https://arb-mainnet.g.alchemy.com/v2/9699FMx-YuVAQVvYsBX6Eay8mbSWcJQD',
        blockNumber: 9759597,
      },
    },

    mainnet: {
      url: NODE_URL_MAINNET,
      accounts: [PKEY_MAINNET],
    },

    testnet: {
      url: NODE_URL_TESTNET,
      accounts: [PKEY_TESTNET],
    },
  },

  docgen: {
    clear: true,
    runOnCompile: false,
  },

  dependencyCompiler: {
    paths: ['@balancer-labs/v2-vault/contracts/interfaces/IVault.sol'],
  },

  gasReporter: {
    enabled: REPORT_GAS === 'true',
  },

  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: true,
  },

  typechain: {
    alwaysGenerateOverloads: true,
  },
};

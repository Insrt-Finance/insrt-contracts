import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import '@tenderly/hardhat-tenderly';
import 'hardhat-abi-exporter';
import 'hardhat-contract-sizer';
import 'hardhat-dependency-compiler';
import 'hardhat-docgen';
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
  TENDERLY_URL_ARBITRUM,
  ARBITRUM_FORK_BLOCK_NUMBER,
} = process.env;

export default {
  solidity: {
    compilers: [
      {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.7.1',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.6.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },

  networks: {
    hardhat: {
      forking: {
        url: NODE_URL_MAINNET,
        blockNumber: 13465420,
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

    tenderly: {
      url: TENDERLY_URL_ARBITRUM,
      accounts: [PKEY_TESTNET],
      blockNumber: ARBITRUM_FORK_BLOCK_NUMBER,
    },
  },

  abiExporter: {
    clear: true,
  },

  docgen: {
    clear: true,
    runOnCompile: false,
  },

  dependencyCompiler: {
    paths: [
      '@balancer-labs/v2-pool-weighted/contracts/WeightedPoolFactory.sol',
      '@balancer-labs/v2-pool-weighted/contracts/smart/InvestmentPoolFactory.sol',
      '@balancer-labs/v2-vault/contracts/interfaces/IVault.sol',
      '@uniswap/v2-periphery/contracts/UniswapV2Router02.sol',
    ],
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

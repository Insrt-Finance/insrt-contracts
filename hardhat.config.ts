import '@nomicfoundation/hardhat-chai-matchers';
import '@nomiclabs/hardhat-ethers';
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

require('./tasks/transferContractOwnership');

const {
  NODE_URL_MAINNET,
  NODE_URL_TESTNET,
  PKEY_MAINNET,
  PKEY_TESTNET,
  REPORT_GAS,
  TENDERLY_URL_MAINNET,
  MAINNET_FORK_BLOCK_NUMBER,
  PKEY_TENDERLY,
  GOERLI_URL_TESTNET,
} = process.env;

export default {
  solidity: {
    compilers: [
      {
        version: '0.8.17',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      // @balancer-labs/*
      {
        version: '0.7.1',
      },
      // @uniswap/v2-periphery
      {
        version: '0.6.6',
      },
    ],
  },

  networks: {
    hardhat: {
      forking: {
        url: NODE_URL_TESTNET,
        blockNumber: 16165493,
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
      url: TENDERLY_URL_MAINNET,
      accounts: [PKEY_MAINNET],
      blockNumber: MAINNET_FORK_BLOCK_NUMBER,
    },

    goerli: {
      url: GOERLI_URL_TESTNET,
      accounts: [PKEY_TESTNET],
    },
  },

  abiExporter: {
    clear: true,
  },

  docgen: {
    clear: true,
    runOnCompile: false,
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

# Insrt Finance

Secure, diversified exposure to NFTs and NFT infrastructure.

## Development

Install dependencies via Yarn:

```bash
yarn install
```

Setup Husky to format code on commit:

```bash
yarn prepare
```

Compile contracts via Hardhat:

```bash
yarn run hardhat compile
```

The Hardhat environment relies on the following environment variables. The `dotenv` package will attempt to read them from the `.env` and `.env.secret` files, if they are present.

| Key                | Description                                                   |
| ------------------ | ------------------------------------------------------------- |
| `NODE_URL_MAINNET` | JSON-RPC node URL for `mainnet` network                       |
| `NODE_URL_TESTNET` | JSON-RPC node URL for `testnet` network                       |
| `PKEY_TESTNET`     | private key for test/development use on `testnet` network     |
| `PKEY_MAINNET`     | private key for production use on `mainnet` network           |
| `REPORT_GAS`       | if `true`, a gas report will be generated after running tests |

### Networks

By default, Hardhat uses the Hardhat Network in-process. Two additional networks, `mainnet` and `testnet` are available, and their behavior is determined by the configuration of environment variables.

### Testing

Test contracts via Hardhat:

```bash
yarn run hardhat test
```

Activate gas usage reporting by setting the `REPORT_GAS` environment variable to `"true"`:

```bash
REPORT_GAS=true yarn run hardhat test
```

Generate a code coverage report using `solidity-coverage`:

```bash
yarn run hardhat coverage
```

### Documentation

A static documentation site can be generated using `hardhat-docgen`:

```bash
yarn run hardhat docgen
```

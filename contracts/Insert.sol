// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { ERC20 } from '@solidstate/contracts/token/ERC20/ERC20.sol';
import { ERC20MetadataStorage } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol';

/**
 * @title Insert Finance governance token
 * @author Insert Finance
 */
contract Insert is ERC20 {
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

    constructor(string memory name, string memory symbol) {
        ERC20MetadataStorage.Layout
            storage metadataLayout = ERC20MetadataStorage.layout();

        metadataLayout.name = name;
        metadataLayout.symbol = symbol;
        metadataLayout.decimals = 18;
    }
}

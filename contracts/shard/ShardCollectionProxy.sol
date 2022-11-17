// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';
import { SolidStateDiamond } from '@solidstate/contracts/proxy/diamond/SolidStateDiamond.sol';
import { ShardCollectionStorage } from './ShardCollectionStorage.sol';

/**
 * @title Diamond proxy used as centrally controlled ShardCollection implementation
 * @dev deployed standalone and passed to ShardVault facets' constructor
 */
contract ShardCollectionProxy is SolidStateDiamond {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address shardVaultDiamond
    ) {
        ERC721MetadataStorage.Layout
            storage metadataStorage = ERC721MetadataStorage.layout();
        ShardCollectionStorage.Layout
            storage shardStorage = ShardCollectionStorage.layout();

        metadataStorage.name = name;
        metadataStorage.symbol = symbol;
        metadataStorage.baseURI = baseURI;
        shardStorage.shardVaultDiamond = shardVaultDiamond;
    }
}

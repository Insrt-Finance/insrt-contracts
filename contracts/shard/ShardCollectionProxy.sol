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
        string memory baseURI
    ) {
        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();

        l.name = name;
        l.symbol = symbol;
        l.baseURI = baseURI;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC1155BaseInternal } from '@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol';
import { ERC1155MetadataStorage } from '@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol';

import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Shard Vault internal functions
 * @dev inherited by all Shard Vault implementation contracts
 */
abstract contract ShardVaultInternal is ERC1155BaseInternal {

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultBase } from './IShardVaultBase.sol';
import { IShardVaultInternal } from './IShardVaultInternal.sol';
import { IShardVaultIO } from './IShardVaultIO.sol';
import { IShardVaultView } from './IShardVaultView.sol';
import { IShardVaultAdmin } from './IShardVaultAdmin.sol';

/**
 * @title complete ShardVault interface
 */
interface IShardVault is
    IShardVaultBase,
    IShardVaultInternal,
    IShardVaultIO,
    IShardVaultView,
    IShardVaultAdmin
{

}

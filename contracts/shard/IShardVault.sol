// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultIO } from './IShardVaultIO.sol';
import { IShardVaultView } from './IShardVaultView.sol';
import { IShardVaultPermissioned } from './IShardVaultPermissioned.sol';

/**
 * @title complete ShardVault interface
 */
interface IShardVault is
    IShardVaultIO,
    IShardVaultView,
    IShardVaultPermissioned
{

}

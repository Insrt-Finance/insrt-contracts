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
    struct FeeParams {
        uint16 saleFeeBP;
        uint16 acquisitionFeeBP;
        uint16 yieldFeeBP;
    }

    struct BufferParams {
        uint256 conversionBuffer;
        uint16 ltvBufferBP;
        uint16 ltvDeviationBP;
    }
}

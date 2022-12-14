// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { IShardVaultManager } from './IShardVaultManager.sol';
import { IShardVault } from '../shard/IShardVault.sol';
import { ShardVaultProxy } from '../shard/ShardVaultProxy.sol';

contract ShardVaultManager is IShardVaultManager, OwnableInternal {
    address public immutable SHARD_VAULT_DIAMOND;
    address public immutable MARKETPLACE_HELPER;

    constructor(address shardVaultDiamond, address marketPlaceHelper) {
        SHARD_VAULT_DIAMOND = shardVaultDiamond;
        MARKETPLACE_HELPER = marketPlaceHelper;
    }

    /**
     * @inheritdoc IShardVaultManager
     */
    function deployShardVault(
        address collection,
        address jpegdVault,
        address jpegdVaultHelper,
        uint256 shardValue,
        uint16 maxSupply,
        uint16 maxUserShards,
        bool isPUSDVault,
        IShardVault.FeeParams memory feeParams,
        IShardVault.BufferParams memory bufferParams
    ) external onlyOwner returns (address deployment) {
        deployment = address(
            new ShardVaultProxy(
                SHARD_VAULT_DIAMOND,
                MARKETPLACE_HELPER,
                collection,
                jpegdVault,
                jpegdVaultHelper,
                shardValue,
                maxSupply,
                maxUserShards,
                isPUSDVault,
                feeParams,
                bufferParams
            )
        );

        emit ShardVaultDeployed(deployment);
    }
}

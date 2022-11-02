// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { IShardVaultManager } from './IShardVaultManager.sol';
import { ShardVaultManagerStorage } from './ShardVaultManagerStorage.sol';
import { ShardVaultProxy } from '../shard/ShardVaultProxy.sol';

contract ShardVaultManager is IShardVaultManager, OwnableInternal {
    address public immutable SHARD_VAULT_DIAMOND;

    constructor(address shardVaultDiamond) {
        SHARD_VAULT_DIAMOND = shardVaultDiamond;
    }

    /**
     * @inheritdoc IShardVaultManager
     */
    function deployShardVault(
        address collection,
        uint256 shardSize,
        uint256 maxShards
    ) external onlyOwner returns (address deployment) {
        deployment = address(
            new ShardVaultProxy(
                SHARD_VAULT_DIAMOND,
                collection,
                shardSize,
                maxShards,
                ++ShardVaultManagerStorage.layout().count
            )
        );

        emit ShardVaultDeployed(deployment);
    }
}

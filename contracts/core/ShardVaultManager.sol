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
        address jpegdVault,
        uint256 shardValue,
        uint256 maxSupply,
        uint256 salesFeeBP,
        uint256 fundraiseFeeBP,
        uint256 yieldFeeBP,
        uint256 bufferBP,
        uint256 deviationBP
    ) external onlyOwner returns (address deployment) {
        deployment = address(
            new ShardVaultProxy(
                SHARD_VAULT_DIAMOND,
                collection,
                jpegdVault,
                shardValue,
                maxSupply,
                ++ShardVaultManagerStorage.layout().count,
                salesFeeBP,
                fundraiseFeeBP,
                yieldFeeBP,
                bufferBP,
                deviationBP
            )
        );

        emit ShardVaultDeployed(deployment);
    }
}

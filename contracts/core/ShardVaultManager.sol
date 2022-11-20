// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { IShardVaultManager } from './IShardVaultManager.sol';
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
        address jpegdVaultHelper,
        uint256 shardValue,
        uint16 maxSupply,
        uint16 saleFeeBP,
        uint16 acquisitionFeeBP,
        uint16 yieldFeeBP,
        uint16 bufferBP,
        uint16 deviationBP,
        uint16 maxUserShards
    ) external onlyOwner returns (address deployment) {
        deployment = address(
            new ShardVaultProxy(
                SHARD_VAULT_DIAMOND,
                collection,
                jpegdVault,
                jpegdVaultHelper,
                shardValue,
                maxSupply,
                saleFeeBP,
                acquisitionFeeBP,
                yieldFeeBP,
                bufferBP,
                deviationBP,
                maxUserShards
            )
        );

        emit ShardVaultDeployed(deployment);
    }
}

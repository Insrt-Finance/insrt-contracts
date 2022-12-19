// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { IShardVault } from '../shard/IShardVault.sol';
import { IShardVaultManager } from './IShardVaultManager.sol';
import { IShardVaultProxy } from '../shard/IShardVaultProxy.sol';
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
        IShardVaultProxy.ShardVaultAddresses memory addresses,
        IShardVaultProxy.ShardVaultUints memory uints,
        string memory name,
        string memory symbol,
        string memory baseURI,
        bool isPUSDVault
    ) external onlyOwner returns (address deployment) {
        addresses.shardVaultDiamond = SHARD_VAULT_DIAMOND;
        addresses.marketPlaceHelper = MARKETPLACE_HELPER;
        deployment = address(
            new ShardVaultProxy(
                addresses,
                uints,
                name,
                symbol,
                baseURI,
                isPUSDVault
            )
        );

        emit ShardVaultDeployed(deployment);
    }
}

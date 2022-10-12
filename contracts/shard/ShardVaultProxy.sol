// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IDiamondReadable } from '@solidstate/contracts/proxy/diamond/readable/IDiamondReadable.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';

import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Upgradeable proxy with externally controlled ShardVault implementation
 */
contract ShardVaultProxy is Proxy {
    address private immutable SHARD_VAULT_DIAMOND;

    constructor(
        address shardVaultDiamond,
        address collection, //may become immutable
        uint256 shardValue, //may become immutable
        uint256 id
    ) {
        SHARD_VAULT_DIAMOND = shardVaultDiamond;

        OwnableStorage.layout().owner = msg.sender;

        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        l.id = id;
        l.collection = collection;
        l.shardValue = shardValue;
    }

    /**
     * @inheritdoc Proxy
     * @notice fetch logic implementation address from external diamond proxy
     */
    function _getImplementation() internal view override returns (address) {
        return IDiamondReadable(SHARD_VAULT_DIAMOND).facetAddress(msg.sig);
    }
}

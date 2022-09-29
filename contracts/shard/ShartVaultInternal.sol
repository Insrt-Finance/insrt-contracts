// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { ERC1155BaseInternal } from '@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol';
import { ERC1155MetadataStorage } from '@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol';

import { Errors } from './Errors.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Shard Vault internal functions
 * @dev inherited by all Shard Vault implementation contracts
 */
abstract contract ShardVaultInternal is ERC1155BaseInternal {
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    function _deposit() internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 amount = msg.value;

        if (amount % l.shardSize != 0) {
            revert Errors.InvalidDepositAmount();
        }
        if (address(this).balance + amount > l.maxCapital) {
            revert Errors.MaxCapitalExceeded();
        }

        uint256 shards = amount / l.shardSize;
        l.owedShards[msg.sender] += shards;
        l.totalShards += shards;
        l.depositors.add(msg.sender);
    }
}

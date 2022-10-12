// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { ERC1155MetadataStorage } from '@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol';
import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { Errors } from './Errors.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Shard Vault internal functions
 * @dev inherited by all Shard Vault implementation contracts
 */
abstract contract ShardVaultInternal is OwnableInternal {
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    modifier onlyProtocolOwner() {
        require(msg.sender == _protocolOwner(), 'Not protocol owner');
        _;
    }

    /**
     * @notice returns the protocol owner
     * @return address of the protocol owner
     */
    function _protocolOwner() internal view returns (address) {
        return IERC173(_owner()).owner();
    }

    /**
     * @notice deposits ETH in exchange for owed shards
     */
    function _deposit() internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 amount = msg.value;
        uint256 shardSize = l.shardSize;
        uint256 owedShards = l.owedShards;

        if (amount % shardSize != 0 || amount == 0) {
            revert Errors.InvalidDepositAmount();
        }
        if (l.invested || l.vaultFull) {
            revert Errors.DepositForbidden();
        }

        uint256 shards = amount / l.shardSize;
        uint256 excessShards;

        if (shards + owedShards > l.maxShards) {
            l.vaultFull = true;
            excessShards = shards + owedShards - l.maxShards;
        }

        shards -= excessShards;

        l.depositorShards[msg.sender] += shards;
        l.depositors.add(msg.sender);
        owedShards += shards;

        if (excessShards > 0) {
            payable(msg.sender).sendValue(excessShards * shardSize);
        }
    }

    /**
     * @notice withdraws ETH for an amount of shards
     * @param shards the amount of shards to "burn" for ETH
     */
    function _withdraw(uint256 shards) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 depositorShards = l.depositorShards[msg.sender];

        if (l.invested || l.vaultFull) {
            revert Errors.WithdrawalForbidden();
        }
        if (depositorShards < shards) {
            revert Errors.InsufficientShards();
        }

        depositorShards -= shards;
        l.owedShards -= shards;

        if (depositorShards == 0) {
            l.depositors.remove(msg.sender);
        }

        payable(msg.sender).sendValue(shards * l.shardSize);
    }
}

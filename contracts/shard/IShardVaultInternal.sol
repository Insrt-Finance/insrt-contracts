// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IOwnableInternal } from '@solidstate/contracts/access/ownable/IOwnableInternal.sol';

interface IShardVaultInternal is IOwnableInternal {
    /**
     * @notice thrown when the deposit amount is not a multiple of shardSize
     */
    error ShardVault__InvalidDepositAmount();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error ShardVault__DepositForbidden();

    /**
     * @notice thrown when the withdraw amount exceeds the owed shards to the sender
     */
    error ShardVault__InsufficientShards();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error ShardVault__WithdrawalForbidden();

    /**
     * @notice thrown when attempt to purchase a punk is made when collection is not punks
     */
    error ShardVault__CollectionNotPunks();

    /**
     * @notice thrown when attempting to act on an unowned asset
     */
    error ShardVault__NotOwned();

    /**
     * @notice thrown when setting a basis point fee value larger than 10000
     */
    error ShardVault__BasisExceeded();

    /**
     * @notice thrown when function called by non-protocol owner
     */
    error ShardVault__NotProtocolOwner();

    /**
     * @notice thrown when function called by non-shard owner
     */
    error ShardVault__NotShardOwner();

    /**
     * @notice thrown when a tokenId is not generated by current vault address
     */
    error ShardVault__VaultTokenIdMismatch();

    /**
     * @notice thrown when attempting to borrow after target LTV amount is reached
     */
    error ShardVault__TargetLTVReached();
}

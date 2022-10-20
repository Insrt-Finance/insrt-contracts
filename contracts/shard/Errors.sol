// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Errors {
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
    error CollectionNotPunks();

    /**
     * @notice thrown when attempting to act on an unowned asset
     */
    error NotOwned();

    /**
     * @notice thrown when setting a basis point fee value larger than 10000
     */
    error BasisExceeded();

    /**
     * @notice thrown when function called by non-protocol owner
     */
    error ShardVault__OnlyProtocolOwner();

    /**
     * @notice thrown when function called by non-shard owner
     */
    error ShardVault__OnlyShardOwner();

    /**
     * @notice thrown when a tokenId is not generated by current vault address
     */
    error ShardVault__VaultTokenIdMismatch();

    /**
     * @notice thrown when function called by non-shard vault
     */
    error ShardCollection__OnlyVault();

    /**
     * @notice thrown when function called by non-protocol owner
     */
    error ShardCollection__OnlyProtocolOwner();
}

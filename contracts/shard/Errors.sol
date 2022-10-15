// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Errors {
    /**
     * @notice thrown when the deposit amount is not a multiple of shardSize
     */
    error InvalidDepositAmount();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error DepositForbidden();

    /**
     * @notice thrown when the withdraw amount exceeds the owed shards to the sender
     */
    error InsufficientShards();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error WithdrawalForbidden();

    /**
     * @notice thrown when function called by non-shard vault
     */
    error OnlyVault();

    /**
     * @notice thrown when function called by non-protocol owner
     */
    error OnlyProtocolOwner();

    /**
     * @notice thrown when function called by non-shard owner
     */
    error OnlyShardOwner();
}

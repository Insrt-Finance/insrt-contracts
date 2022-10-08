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
     * @notice thrown when attempt to purchase a punk is made when collection is not punks
     */
    error CollectionNotPunks();

    /**
     * @notice thrown when attempting to act on an unowned asset
     */
    error NotOwned();

    /**
     * @notice thrown when caller is not protocol owner
     */
    error NotProtocolOwner();
}

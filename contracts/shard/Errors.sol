// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

library Errors {
    /**
     * @notice thrown when the deposit amount is not a multiple of shardSize
     */
    error InvalidDepositAmount();

    /**
     * @notice thrown when the deposit amount added to ETH balance would exceed
     */
    error MaxCapitalExceeded();

    /**
     * @notice thrown when the withdraw amount exceeds the owed shards to the sender
     */
    error InsufficientShards();

    /**
     * @notice thrown when a depositor attempts to withdraw but the vault has already invested
     */
    error WithdrawalPeriodElapsed();
}

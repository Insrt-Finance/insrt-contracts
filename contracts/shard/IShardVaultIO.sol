// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ShardVault Input Output Interface
 */
interface IShardVaultIO {
    /**
     * @notice deposit ETH
     * @dev records owed amount to depositor
     */
    function deposit() external payable;

    /**
     * @notice withdraw ETH for shards
     * @dev reduces shards owed to withdrawer, only allowed before investing funds
     */
    function withdraw(uint256 shards) external payable;
}

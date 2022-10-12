// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title interface for ShardVaultView facet
 */
interface IShardVaultView {
    /**
     * @notice returns amount of shards escrowed by vault for an account
     * @param account address of account owed shards
     */
    function depositorShards(address account) external view returns (uint256);

    /**
     * @notice returns total shards escrowed by vault
     */
    function owedShards() external view returns (uint256);

    /**
     * @notice returns ETH value of shard
     */
    function shardSize() external view returns (uint256);
}

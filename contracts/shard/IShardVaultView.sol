// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title interface for ShardVaultView facet
 */
interface IShardVaultView {
    /**
     * @notice returns total shards minted
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice returns ETH value of shard at time of mint
     */
    function shardValue() external view returns (uint256);

    /**
     * @notice return ShardCollection address
     */
    function shardCollection() external view returns (address);
}

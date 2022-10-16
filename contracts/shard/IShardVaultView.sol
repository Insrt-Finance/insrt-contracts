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
     * @notice returns maximum possible minted shards
     */
    function maxSupply() external view returns (uint256);

    /**
     * @notice returns ETH value of shard at time of mint
     */
    function shardValue() external view returns (uint256);

    /**
     * @notice return ShardCollection address
     */
    function shardCollection() external view returns (address);

    /**
     * @notice return minted token count
     * @dev does not reduce when tokens are burnt
     */
    function count() external view returns (uint256);
}

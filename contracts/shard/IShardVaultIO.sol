// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ShardVault Input Output Interface
 */
interface IShardVaultIO {
    /**
     * @notice deposit ETH
     */
    function deposit() external payable;

    /**
     * @notice burn held shards before NFT acquisition and withdraw corresponding ETH
     * @param shardIds list of ids of shards to burn
     */
    function withdraw(uint256[] memory shardIds) external;

    /**
     * @notice sends yield in the form of ETH + JPEG tokens to account
     * @param shardIds array of shard IDs to claim with
     * @param tokenIdDOI Dawn of INSRT token ID used to apply yieldFeeBP discount
     */
    function claimYield(uint256[] memory shardIds, uint256 tokenIdDOI) external;

    /**
     * @notice returns excess ETH left over after vault has invested
     * @param shardIds array of shard IDs to claim with
     */
    function claimExcessETH(uint256[] memory shardIds) external;
}

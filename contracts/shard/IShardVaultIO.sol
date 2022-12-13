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
    function withdraw(uint256[] memory shardIds) external payable;

    /**
     * @notice claim yield/excess ETH upon shard transfer
     * @dev only SHARD_COLLECTION proxy may call
     * @param from address transferring
     * @param to address receiving
     * @param tokenId id of shard being transferred
     */
    function implicitClaim(address from, address to, uint256 tokenId) external;

    /**
     * @notice sends yield in the form of ETH + JPEG tokens to account
     * @param tokenIds array of shard IDs to claim with
     */
    function claimYield(uint256[] memory tokenIds) external;

    /**
     * @notice returns excess ETH left over after vault has invested
     * @param tokenIds array of shard IDs to claim with
     */
    function claimExcessETH(uint256[] memory tokenIds) external;
}

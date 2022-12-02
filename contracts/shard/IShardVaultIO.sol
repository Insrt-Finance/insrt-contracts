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
}

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
     * @param tokenIds list of ids of shards to burn
     */
    function withdraw(uint256[] memory tokenIds) external payable;

    /**
     * @notice before shard transfer hook
     * @dev only SHARD_COLLECTION proxy may call - purpose is to maintain correct balances
     * @param from address transferring
     * @param to address receiving
     */
    function beforeShardTransfer(address from, address to) external;
}

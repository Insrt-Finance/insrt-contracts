// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ShardVault Manager contract interface
 */
interface IShardVaultManager {
    /**
     * @notice event logged upon ShardVaultProxy deployment
     * @param deployment address of ShardVaultProxy
     */
    event ShardVaultDeployed(address deployment);

    /**
     * @notice returns address of ShardVault Diamond contract
     * @return address of ShardVaultDiamond
     */
    function SHARD_VAULT_DIAMOND() external view returns (address);

    /**
     * @notice deploys a ShardVaultProxy
     * @param collection the address of the NFT collection contract
     * @param shardSize the size in ETH of each shard
     * @return deployment address of ShardVaultProxy deployed
     */
    function deployShardVault(address collection, uint256 shardSize)
        external
        returns (address deployment);
}

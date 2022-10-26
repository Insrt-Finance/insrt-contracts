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
     * @param jpegdVault the jpeg'd NFT vault corresponding to the collection
     * @param shardValue the ETH value of each shard
     * @param maxSupply maximum shards to be minted by vault
     * @param salesFeeBP sales fee basis points
     * @param fundraiseFeeBP fundraise fee basis points
     * @param yieldFeeBP yield fee basis points
     * @return deployment address of ShardVaultProxy deployed
     */
    function deployShardVault(
        address collection,
        address jpegdVault,
        uint256 shardValue,
        uint256 maxSupply,
        uint256 salesFeeBP,
        uint256 fundraiseFeeBP,
        uint256 yieldFeeBP
    ) external returns (address deployment);
}

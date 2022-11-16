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
     * @param jpegdVaultHelper the jpeg'd NFT Vault helper contract used for 
       non-ERC721/1155 compiant collections
     * @param shardValue the ETH value of each shard
     * @param maxSupply maximum shards to be minted by vault
     * @param saleFeeBP sales fee basis points
     * @param acquisitionFeeBP acquisition fee basis points
     * @param yieldFeeBP yield fee basis points
     * @param bufferBP LTV buffer basis points
     * @param deviationBP LTV deviation basis points
     * @param maxShardsPerUser maximum amount of shards allowed per user
     * @return deployment address of ShardVaultProxy deployed
     */
    function deployShardVault(
        address collection,
        address jpegdVault,
        address jpegdVaultHelper,
        uint256 shardValue,
        uint16 maxSupply,
        uint16 saleFeeBP,
        uint16 acquisitionFeeBP,
        uint16 yieldFeeBP,
        uint16 bufferBP,
        uint16 deviationBP,
        uint16 maxShardsPerUser
    ) external returns (address deployment);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVault } from '../shard/IShardVault.sol';

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
     * @notice returns address of MarketPlaceHelper implementation contract
     * @return address of MarketPlaceHelper implementation
     */
    function MARKETPLACE_HELPER() external view returns (address);

    /**
     * @notice deploys a ShardVaultProxy
     * @param collection the address of the NFT collection contract
     * @param jpegdVault the jpeg'd NFT vault corresponding to the collection
     * @param jpegdVaultHelper the jpeg'd NFT Vault helper contract used for
       non-ERC721/1155 compiant collections
     * @param shardValue the ETH value of each shard
     * @param maxSupply maximum shards to be minted by vault
     * @param maxUserShards maximum amount of shards allowed per user
     * @param isPUSDVault indicates whether vault should be allowed to call PETH or PUSD functions
     * @param feeParams struct containing basis point values for all fees (sale, acquisition, yield)
     * @param bufferParams struct containing basis point values for all buffers (ltv, ltvDeviation, conversion)
     * @dev conversion buffer requires increased accuracy thus has more significant figures than BASIS
     */
    function deployShardVault(
        address collection,
        address jpegdVault,
        address jpegdVaultHelper,
        uint256 shardValue,
        uint16 maxSupply,
        uint16 maxUserShards,
        bool isPUSDVault,
        IShardVault.FeeParams memory feeParams,
        IShardVault.BufferParams memory bufferParams
    ) external returns (address deployment);
}

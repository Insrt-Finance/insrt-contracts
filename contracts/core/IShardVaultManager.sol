// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ShardVaultProxy } from '../shard/ShardVaultProxy.sol';

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
     * @param feeParams struct containing basis point values for all fees (sale, acquisition, yield)
     * @param bufferParams struct containing basis point values for all buffers (ltv, ltvDeviation, conversion)
     * @dev for pETH conversion buffer, basis points have insufficient accuracy thus the buffer is increased by two decimal points
     */
    function deployShardVault(
        address collection,
        address jpegdVault,
        address jpegdVaultHelper,
        uint256 shardValue,
        uint256 maxSupply,
        ShardVaultProxy.FeeParams memory feeParams,
        ShardVaultProxy.BufferParams memory bufferParams
    ) external returns (address deployment);
}

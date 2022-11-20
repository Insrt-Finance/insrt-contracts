// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title interface for ShardVaultView facet
 */
interface IShardVaultView {
    /**
     * @notice returns total shards minted
     */
    function totalSupply() external view returns (uint16);

    /**
     * @notice returns maximum possible minted shards
     */
    function maxSupply() external view returns (uint16);

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
    function count() external view returns (uint16);

    /**
     * @notice formats a tokenId given the internalId and address of ShardVault contract
     * @param internalId the internal ID
     * @return tokenId the formatted tokenId
     */
    function formatTokenId(uint96 internalId)
        external
        view
        returns (uint256 tokenId);

    /**
     * @notice parses a tokenId to extract seeded vault address and internalId
     * @param tokenId tokenId to parse
     * @return vault seeded vault address
     * @return internalId internal ID
     */
    function parseTokenId(uint256 tokenId)
        external
        pure
        returns (address vault, uint96 internalId);

    /**
     * @notice return isInvested flag state
     * @return bool isInvested flag
     */
    function isInvested() external view returns (bool);

    /**
     * @notice return array of NFT ids owned by the vault
     * @return ids array of owned token IDs
     */
    function ownedTokenIds() external view returns (uint256[] memory ids);

    /**
     * @notice returns sum of total fees (sale, yield, acquisition) accrued over the entire lifetime of the vault
     * @dev accounts for fee withdrawals
     * @return fees accrued fees
     */
    function accruedFees() external view returns (uint256 fees);

    /**
     * @notice returns acquisition fee BP
     * @return feeBP basis points of acquisition fee
     */
    function acquisitionFeeBP() external view returns (uint16 feeBP);

    /**
     * @notice returns sale fee BP
     * @return feeBP basis points of sale fee
     */
    function saleFeeBP() external view returns (uint16 feeBP);

    /**
     * @notice returns yield fee BP
     * @return feeBP basis points of yield fee
     */
    function yieldFeeBP() external view returns (uint16 feeBP);

    /**
     * @notice return maxShardsPerUser
     * @return uint16 maxShardsPerUser value
     */
    function maxShardsPerUser() external view returns (uint16);

    /**
     * @notice return vault shards owned by an account
     * @param account address owning shards
     * @return uint16 shards owned by account
     */
    function shardBalances(address account) external view returns (uint16);

    /**
     * @notice return amount of shards reserved for whitelist
     * @return uint16 amount of shards reserved for whitelist
     */
    function whitelistShards() external view returns (uint16);
}

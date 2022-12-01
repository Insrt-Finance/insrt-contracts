// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title interface for ShardVaultView facet
 */
interface IShardVaultView {
    /**
     * @notice returns total shards minted
     * @return totalSupply total minted shards amount
     */
    function totalSupply() external view returns (uint16 totalSupply);

    /**
     * @notice returns maximum possible minted shards
     * @return maxSupply maximum possible minted shards
     */
    function maxSupply() external view returns (uint16 maxSupply);

    /**
     * @notice returns ETH value of shard at time of mint
     * @return shardValue ETH value of a shard
     */
    function shardValue() external view returns (uint256 shardValue);

    /**
     * @notice return ShardCollection address
     * @return shardCollection address
     */
    function shardCollection() external view returns (address shardCollection);

    /**
     * @notice return minted token count
     * @dev does not reduce when tokens are burnt
     * @return count minted token count
     */
    function count() external view returns (uint16 count);

    /**
     * @notice formats a tokenId given the internalId and address of ShardVault contract
     * @param internalId the internal ID
     * @return tokenId the formatted tokenId
     */
    function formatTokenId(
        uint96 internalId
    ) external view returns (uint256 tokenId);

    /**
     * @notice parses a tokenId to extract seeded vault address and internalId
     * @param tokenId tokenId to parse
     * @return vault seeded vault address
     * @return internalId internal ID
     */
    function parseTokenId(
        uint256 tokenId
    ) external pure returns (address vault, uint96 internalId);

    /**
     * @notice return isInvested flag state
     * @return isInvested isInvested flag
     */
    function isInvested() external view returns (bool isInvested);

    /**
     * @notice return array of NFT ids owned by the vault
     * @return ownedTokenIds array of owned token IDs
     */
    function ownedTokenIds()
        external
        view
        returns (uint256[] memory ownedTokenIds);

    /**
     * @notice returns total debt owed to jpeg'd vault for a given token
     * @param tokenId id of token position pertains to
     * @return debt total debt owed
     */
    function totalDebt(uint256 tokenId) external view returns (uint256 debt);

    /**
     * @notice returns amount of AutoComp LP shares needed to be burnt during unstaking
     *         to result in a given amount of pUSD
     * @param pUSD desired pUSD amount
     * @return autoComp required AutoComp LP shares
     */
    function queryAutoCompForPUSD(
        uint256 pUSD
    ) external view returns (uint256 autoComp);

    /**
     * @notice returns amount of AutoComp LP shares needed to be burnt during unstaking
     *         to result in a given amount of pETH
     * @param pETH desired pETH amount
     * @return autoComp required AutoComp LP shares
     */
    function queryAutoCompForPETH(
        uint256 pETH
    ) external view returns (uint256 autoComp);

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
     * @notice return the maximum shards a user is allowed to mint
     * @dev theoretically a user may acquire more than this amount via transfers, but once this amount is exceeded
     * said user may not deposit more
     * @return maxShards maxShardsPerUser value
     */
    function maxUserShards() external view returns (uint16 maxShards);

    /**
     * @notice return quantity of vault shards owned by an account
     * @param account address owning shards
     * @return shards quantity of shards
     */
    function userShards(address account) external view returns (uint16 shards);

    /**
     * @notice return amount of shards reserved for whitelist
     * @return reservedShards amount of shards reserved for whitelist
     */
    function reservedShards() external view returns (uint16 reservedShards);

    /**
     * @notice returns address of market place helper
     * @return MARKETPLACE_HELPER address
     */
    function marketplaceHelper() external view returns (address);
}

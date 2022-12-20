// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title interface for ShardVaultView facet
 */
interface IShardVaultView {
    /**
     * @notice returns maximum possible minted shards
     * @return maxSupply maximum possible minted shards
     */
    function maxSupply() external view returns (uint64 maxSupply);

    /**
     * @notice returns ETH value of shard at time of mint
     * @return shardValue ETH value of a shard
     */
    function shardValue() external view returns (uint256 shardValue);

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
     * @param shardId id of token position pertains to
     * @return debt total debt owed
     */
    function totalDebt(uint256 shardId) external view returns (uint256 debt);

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
     * @notice returns sum of total fees (sale, yield, acquisition) accrued over the entire lifetime of the vault; accounts for fee withdrawals
     * @return fees accrued fees
     */
    function accruedFees() external view returns (uint256 fees);

    /**
     * @notice returns sum of total jpeg due to yield fee accrued over the entire lifetime of the vault
     * @dev accounts for jpeg withdrawals
     * @return jpeg accrued jpeg
     */
    function accruedJPEG() external view returns (uint256 jpeg);

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
     * @notice return the maximum shards a user is allowed to mint; theoretically a user may acquire more than this amount via transfers,
     * but once this amount is exceeded said user may not deposit more
     * @return maxBalance maxMintBalance value
     */
    function maxMintBalance() external view returns (uint64 maxBalance);

    /**
     * @notice return amount of shards reserved for whitelist
     * @return reservedSupply amount of shards reserved for whitelist
     */
    function reservedSupply() external view returns (uint64 reservedSupply);

    /**
     * @notice returns the authorized status of an account
     * @param account address to check status of
     * @return isAuthorized authorized status of account
     */
    function isAuthorized(
        address account
    ) external view returns (bool isAuthorized);

    /**
     * @notice returns address of market place helper
     * @return MARKETPLACE_HELPER address
     */
    function marketplaceHelper() external view returns (address);

    /**
     * @notice fetches claimed JPEG for shard id
     * @param shardId id of shard to check
     * @return claimedJPEGPerShard claimed JPEG for given shard
     */
    function claimedJPEGPerShard(
        uint256 shardId
    ) external view returns (uint256 claimedJPEGPerShard);

    /**
     * @notice fetches claimed ETH for shard id
     * @param shardId id of shard to check
     * @return claimedETHPerShard claimed ETH for given shard
     */
    function claimedETHPerShard(
        uint256 shardId
    ) external view returns (uint256 claimedETHPerShard);

    /**
     * @notice fetches accumulated JPEG per shard
     * @return cumulativeJPEGPerShard cumulative JPEG per shard value
     */
    function cumulativeJPEGPerShard()
        external
        view
        returns (uint256 cumulativeJPEGPerShard);

    /**
     * @notice fetches accumulated ETH per shard
     * @return cumulativeETHPerShard cumulative ETH per shard value
     */
    function cumulativeETHPerShard()
        external
        view
        returns (uint256 cumulativeETHPerShard);

    /**
     * @notice returns the yield claiming status of the vault
     * @return isYieldClaiming the yield claiming status of the vault
     */
    function isYieldClaiming() external view returns (bool isYieldClaiming);

    /**
     * @notice returns timestamp of whitelist end
     * @return whitelistEndsAt timestamp of whitelist end
     */
    function whitelistEndsAt() external view returns (uint48 whitelistEndsAt);

    /**
     * @notice returns treasury address
     * @return treasury address of treasury
     */
    function treasury() external view returns (address treasury);

    /**
     * @notice returns the isEnabled status of the vault
     * @return isEnabled status of isEnabled of the vault
     */
    function isEnabled() external view returns (bool isEnabled);
}

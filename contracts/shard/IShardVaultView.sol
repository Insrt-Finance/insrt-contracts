// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title interface for ShardVaultView facet
 */
interface IShardVaultView {
    /**
     * @notice returns total shards minted
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice returns maximum possible minted shards
     */
    function maxSupply() external view returns (uint256);

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
    function count() external view returns (uint256);

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
     * @notice return invested flag state
     * @return bool invested flag
     */
    function invested() external view returns (bool);

    /**
     * @notice return array with owned token IDs
     * @return ids array of owned token IDs
     */
    function ownedTokenIds() external view returns (uint256[] memory ids);

    /**
     * @notice returns accrued fees
     * @return fees accrued fees
     */
    function accruedFees() external view returns (uint256 fees);

    /**
     * @notice returns acquisition fee BP
     * @return feeBP basis points of acquisition fee
     */
    function acquisitionFeeBP() external view returns (uint256 feeBP);

    /**
     * @notice returns sale fee BP
     * @return feeBP basis points of sale fee
     */
    function saleFeeBP() external view returns (uint256 feeBP);

    /**
     * @notice returns yield fee BP
     * @return feeBP basis points of yield fee
     */
    function yieldFeeBP() external view returns (uint256 feeBP);
}

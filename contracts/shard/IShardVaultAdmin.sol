// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IMarketPlaceHelper } from '../helpers/IMarketPlaceHelper.sol';

/**
 * @title ShardVaultAdmin interace
 */
interface IShardVaultAdmin {
    /**
     * @notice purchases a punk from CyrptoPunksMarket
     * @param calls  array of EncodedCall structs containing information to execute necessary low level
     * calls to purchase a punk
     * @param punkId id of punk
     */
    function purchasePunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId
    ) external payable;

    /**
     * @notice borrows pUSD by collateralizing a punk on JPEG'd
     * @param punkId id of punk
     * @param borrowAmount amount to be borrowed
     * @param insure whether to insure position
     * @return pUSD borrowed pUSD
     * @dev insuring is explained here: https://github.com/jpegd/core/blob/7581b11fc680ab7004ea869226ba21be01fc0a51/contracts/vaults/NFTVault.sol#L563
     */
    function collateralizePunkPUSD(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external returns (uint256 pUSD);

    /**
     * @notice borrows pETH by collateralizing a punk on JPEG'd
     * @param punkId id of punk
     * @param borrowAmount amount to be borrowed
     * @param insure whether to insure position
     * @return pETH borrowed pETH
     * @dev insuring is explained here: https://github.com/jpegd/core/blob/7581b11fc680ab7004ea869226ba21be01fc0a51/contracts/vaults/NFTVault.sol#L563
     */
    function collateralizePunkPETH(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external returns (uint256 pETH);

    /**
     * @notice stakes pUSD in curve meta pool, then stakes curve LP in JPEG'd citadel,
     * and finally stakes citadel tokens in JPEG'd autocompounder
     * @param amount pUSD amount
     * @param minCurveLP minimum LP to be accepted as return from curve staking
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     * the pool to deposit into
     * @return shares deposited into JPEGd autocompounder
     */
    function stakePUSD(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) external returns (uint256 shares);

    /**
     * @notice stakes an amount of pETH into JPEGd autocompounder and then into JPEGd PETH_CITADEL
     * @param amount amount of pETH to stake
     * @param minCurveLP minimum LP to receive from pETH staking into curve
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     * the pool to deposit into
     * @return shares deposited into JPEGd autocompounder
     */
    function stakePETH(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) external returns (uint256 shares);

    /**
     * @notice purchase and collateralize a punk, and stake amount of pUSD borrowed in Curve & JPEG'd
     * @param calls  array of EncodedCall structs containing information to execute necessary low level
     * calls to purchase a punk
     * @param punkId id of punk
     * @param borrowAmount amount to be borrowed
     * @param minCurveLP minimum LP to be accepted as return from curve staking
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     * the pool to deposit into
     * @param insure whether to insure position
     */
    function investPunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId,
        uint256 borrowAmount,
        uint256 minCurveLP,
        uint256 poolInfoIndex,
        bool insure
    ) external;

    /**
     * @notice sets the acquisition fee BP
     * @param feeBP basis points value of fee
     */
    function setAcquisitionFee(uint16 feeBP) external;

    /**
     * @notice sets the sale fee BP
     * @param feeBP basis points value of fee
     */
    function setSaleFee(uint16 feeBP) external;

    /**
     * @notice sets the Yield fee BP
     * @param feeBP basis points value of fee
     */
    function setYieldFee(uint16 feeBP) external;

    /**
     * @notice sets the maxSupply of shards
     * @param maxSupply the maxSupply of shards
     */
    function setMaxSupply(uint16 maxSupply) external;

    /**
     * @notice sets the whitelistEndsAt timestamp
     * @param whitelistEndsAt timestamp of whitelist end
     */
    function setWhitelistEndsAt(uint256 whitelistEndsAt) external;

    /**
     * @notice sets the maximum amount of shard to be minted during whitelist
     * @param whitelistShards whitelist shard amount
     */
    function setWhitelistShads(uint16 whitelistShards) external;

    /**
     * @notice sets the isEnabled flag
     * @param isEnabled boolean value
     */
    function setIsEnabled(bool isEnabled) external;

    /**
     * @notice sets the whitelist deadline and allows deposits
     * @param whitelistEndsAt whitelist deadline timestamp
     * @param whitelistShards whitelist shard amount
     */
    function initiateWhitelistAndDeposits(
        uint256 whitelistEndsAt,
        uint16 whitelistShards
    ) external;
}

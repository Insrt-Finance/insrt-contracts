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
     * @param isFinalPurchase indicates whether this is the final purchase for the vault, to free up
     * any excess ETH for claiming
     */
    function purchasePunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId,
        bool isFinalPurchase
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
     * @param isFinalPurchase indicates whether this is the final purchase for the vault, to free up
     * any excess ETH for claiming
     */
    function investPunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId,
        uint256 borrowAmount,
        uint256 minCurveLP,
        uint256 poolInfoIndex,
        bool insure,
        bool isFinalPurchase
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
    function setWhitelistEndsAt(uint64 whitelistEndsAt) external;

    /**
     * @notice sets the maximum amount of shard to be minted during whitelist
     * @param reservedShards reserved shard amount
     */
    function setReservedShards(uint16 reservedShards) external;

    /**
     * @notice sets the isEnabled flag, allowing or prohibiting deposits
     * @param isEnabled boolean value
     */
    function setIsEnabled(bool isEnabled) external;

    /**
     * @notice sets the whitelist deadline and allows deposits
     * @param whitelistEndsAt whitelist deadline timestamp
     * @param reservedShards whitelist shard amount
     */
    function initiateWhitelistAndDeposits(
        uint64 whitelistEndsAt,
        uint16 reservedShards
    ) external;

    /**
     * @notice return the maximum shards a user is allowed to mint
     * @dev theoretically a user may acquire more than this amount via transfers, but once this amount is exceeded
     * said user may not deposit more
     * @param maxUserShards new maxUserShards value
     */
    function setMaxUserShards(uint16 maxUserShards) external;

    /**
     * @notice unstakes from JPEG'd LPFarming, then from JPEG'd citadel, then from curve LP
     * @param amount amount of shares of auto-compounder to burn
     * @param minPUSD minimum pUSD to receive from curve pool
     * @param poolInfoIndex the index of the JPEG'd LPFarming pool
     * @return pUSD pUSD amount returned
     */
    function unstakePUSD(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex
    ) external returns (uint256 pUSD);

    /**
     * @notice unstakes from JPEG'd LPFarming, then from JPEG'd citadel, then from curve LP
     * @param amount amount of shares of auto-compounder to burn
     * @param minPETH minimum pETH to receive from curve pool
     * @param poolInfoIndex the index of the JPEG'd LPFarming pool
     * @return pETH pETH amount returned
     */
    function unstakePETH(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex
    ) external returns (uint256 pETH);

    /**
     * @notice liquidates all staked tokens in order to pay back loan, retrieves collateralized punk
     * @param punkId id of punk position pertains to
     * @param minTokenAmount minimum token (pETH/pUSD) to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param isPUSD indicates whether loan position is denominated in pUSD or pETH
     */
    function closePunkPosition(
        uint256 punkId,
        uint256 minTokenAmount,
        uint256 poolInfoIndex,
        bool isPUSD
    ) external;

    /**
     * @notice makes a debt payment to a loan position
     * @param minPUSD minimum pUSD to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param punkId id of punk position pertains to
     * @return paidDebt amount of debt repaid
     */
    function repayLoanPUSD(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 punkId
    ) external returns (uint256 paidDebt);

    /**
     * @notice makes a debt payment for a collateralized NFT in jpeg'd
     * @param amount amount of pETH intended to be repaid
     * @param minPETH minimum pETH to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param punkId id of punk position pertains to
     * @return paidDebt amount of debt repaid
     */
    function repayLoanPETH(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex,
        uint256 punkId
    ) external returns (uint256 paidDebt);

    /**
     * @notice makes loan repayment in PUSD without unstaking
     * @param amount payment amount
     * @param punkId id of punk
     */
    function directRepayLoanPUSD(uint256 amount, uint256 punkId) external;

    /**
     * @notice makes loan repayment in PETH without unstaking
     * @param amount payment amount
     * @param punkId id of punk
     */
    function directRepayLoanPETH(uint256 amount, uint256 punkId) external;

    /**
     * @notice lists a punk on CryptoPunk market place using MarketPlaceHelper contract
     * @param calls encoded call array for listing the punk
     * @param punkId id of punk to list
     */
    function listPunk(
        IMarketPlaceHelper.EncodedCall[] memory calls,
        uint256 punkId
    ) external;

    /**
     * @notice provides (makes available) yield in the form of ETH and JPEG tokens
     * @dev unstakes some of the pETH position to convert to yield, and claims
     * pending rewards in LP_FARM to receive JPEG
     * @param autoComp amount of autoComp tokens to unstake
     * @param minETH minimum ETH to receive after unstaking
     * @param poolInfoIndex the index of the LP_FARM pool which corresponds to staking PETH-ETH curveLP
     * @return providedETH total ETH provided as yield
     * @return providedJPEG total JEPG provided as yield
     */
    function provideYieldPETH(
        uint256 autoComp,
        uint256 minETH,
        uint256 poolInfoIndex
    ) external payable returns (uint256 providedETH, uint256 providedJPEG);
}

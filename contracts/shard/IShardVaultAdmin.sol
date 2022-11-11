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
     * @notice liquidates all staked tokens in order to pay back loan, retrieves collateralized punk,
     *         and lists punk for sale
     * @param punkId id of punk position pertains to
     * @param minPUSD minimum pUSD to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param ask minimum accepted sale price of punk
     */
    function closePunkPosition(
        uint256 punkId,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 ask
    ) external;

    /**
     * @notice makes a downpayment to a loan position
     * @param minPUSD minimum pUSD to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param punkId id of punk position pertains to
     * @return paidDebt amount of debt repaid
     */
    function downPaymentPUSD(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 punkId
    ) external returns (uint256 paidDebt);

    /**
     * @notice makes a downpayment for a collateralized NFT in jpeg'd
     * @param amount amount of pETH intended to be repaid
     * @param minPETH minimum pETH to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param punkId id of punk position pertains to
     * @return paidDebt amount of debt repaid
     */
    function downPaymentPETH(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex,
        uint256 punkId
    ) external returns (uint256 paidDebt);

    /**
     * @notice stakes a jpeg card
     * @param tokenId id of card in card collection
     */
    function stakeCard(uint256 tokenId) external;

    /**
     * @notice unstakes a jpeg card
     * @param tokenId id of card in card collection
     */
    function unstakeCard(uint256 tokenId) external;

    /**
     * @notice transfers a jpeg card to an address
     * @param tokenId id of card in card collection
     * @param to address to transfer to
     */
    function transferCard(uint256 tokenId, address to) external;
}

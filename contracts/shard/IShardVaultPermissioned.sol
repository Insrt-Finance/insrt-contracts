// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ShardVaultPermissioned interace
 */
interface IShardVaultPermissioned {
    /**
     * @notice purchases a punk from CyrptoPunksMarket
     * @param punkId id of punk
     */
    function purchasePunk(uint256 punkId) external payable;

    /**
     * @notice borrows pUSD by collateralizing a punk on JPEG'd
     * @param punkId id of punk
     * @param insure whether to insure position
     * @dev insuring is explained here: https://github.com/jpegd/core/blob/7581b11fc680ab7004ea869226ba21be01fc0a51/contracts/vaults/NFTVault.sol#L563
     */
    function collateralizePunk(uint256 punkId, bool insure) external;

    /**
     * @notice stakes pUSD in curve meta pool, then stakes curve LP in JPEG'd citadel,
     *         and finally stakes citadel tokens in JPEG'd autocompounder
     * @param amount pUSD amount
     * @param minCurveLP minimum LP to be accepted as return from curve staking
     */
    function stake(uint256 amount, uint256 minCurveLP) external;

    /**
     * @notice purchase and collateralize a punk, and stake amount of pUSD borrowed in Curve
     *         & JPEG'd
     * @param punkId id of punk
     * @param minCurveLP minimum LP to be accepted as return from curve staking
     * @param insure whether to insure position
     */
    function investPunk(
        uint256 punkId,
        uint256 minCurveLP,
        bool insure
    ) external;

    /**
     * @notice sets the fundraise fee BP
     * @param feeBP basis points value of fee
     */
    function setFundraiseFee(uint256 feeBP) external;

    /**
     * @notice sets the sales fee BP
     * @param feeBP basis points value of fee
     */
    function setSalesFee(uint256 feeBP) external;

    /**
     * @notice sets the Yield fee BP
     * @param feeBP basis points value of fee
     */
    function setYieldFee(uint256 feeBP) external;
}

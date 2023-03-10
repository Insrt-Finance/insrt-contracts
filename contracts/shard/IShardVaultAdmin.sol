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
     * @dev insuring is explained here: https://github.com/jpegd/core/blob/7581b11fc680ab7004ea869226ba21be01fc0a51/contracts/vaults/NFTVault.sol#L563
     * @param punkId id of punk
     * @param borrowAmount amount to be borrowed
     * @param insure whether to insure position
     * @return pUSD borrowed pUSD
     */
    function collateralizePunkPUSD(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external returns (uint256 pUSD);

    /**
     * @notice borrows pETH by collateralizing a punk on JPEG'
     * @dev insuring is explained here: https://github.com/jpegd/core/blob/7581b11fc680ab7004ea869226ba21be01fc0a51/contracts/vaults/NFTVault.sol#L563
     * @param punkId id of punk
     * @param borrowAmount amount to be borrowed
     * @param insure whether to insure position
     * @return pETH borrowed pETH
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
     * @notice withdraw JPEG and ETH accrued protocol fees, and send to TREASURY address
     * @return feesETH total ETH fees withdrawn
     * @return feesJPEG total JPEG fees withdrawn
     */
    function withdrawFees()
        external
        returns (uint256 feesETH, uint256 feesJPEG);

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
    function setMaxSupply(uint64 maxSupply) external;

    /**
     * @notice sets the whitelistEndsAt timestamp
     * @param whitelistEndsAt timestamp of whitelist end
     */
    function setWhitelistEndsAt(uint48 whitelistEndsAt) external;

    /**
     * @notice sets the maximum amount of shards to be minted during whitelist
     * @param reservedSupply reserved shard amount
     */
    function setReservedSupply(uint64 reservedSupply) external;

    /**
     * @notice sets the isEnabled flag, allowing or prohibiting deposits
     * @param isEnabled boolean value
     */
    function setIsEnabled(bool isEnabled) external;

    /**
     * @notice grants or revokes the 'authorized' state to an account
     * @param account address of account to grant/revoke 'authorized'
     * @param isAuthorized value of 'authorized' state
     */
    function setAuthorized(address account, bool isAuthorized) external;

    /**
     * @notice sets the whitelist deadline and allows deposits
     * @param whitelistEndsAt whitelist deadline timestamp
     * @param reservedSupply whitelist shard amount
     */
    function initiateWhitelistAndDeposits(
        uint48 whitelistEndsAt,
        uint64 reservedSupply
    ) external;

    /**
     * @notice return the maximum shards a user is allowed to mint; theoretically a user may acquire more than this amount via transfers,
     * but once this amount is exceeded said user may not deposit more
     * @param maxMintBalance new maxMintBalance value
     */
    function setMaxMintBalance(uint64 maxMintBalance) external;

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
     * @param punkId punkId pertinent to position
     * @param minPETH minimum pETH to receive from curveLP after unstake
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param minETH minimum amount of ETH to receive from curveLP after exchange
     */
    function closePunkPositionPETH(
        uint256 punkId,
        uint256 minPETH,
        uint256 poolInfoIndex,
        uint256 minETH
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

    /**
     * @notice makes the any ETH besides the vault accrued fees claimable
     */
    function makeUnusedETHClaimable() external;

    /**
     * @notice accepts a punk bid and withdraws any proceeds generated from punk sales
     * @dev called from marketPlaceHelper contract to transfer ETH proceeds from punk sale
     * @param calls encoded calls required to accept bid on an asset
     * @param punkId id of punk to accept bid on
     */
    function acceptPunkBid(
        IMarketPlaceHelper.EncodedCall[] memory calls,
        uint256 punkId
    ) external;

    /**
     * @notice sets a new baseURI for ERC721Metadata
     * @param baseURI the new baseURI
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @notice sets the new value of ltvBufferBP
     * @param ltvBufferBP new value of ltvBufferBP
     */
    function setLtvBufferBP(uint16 ltvBufferBP) external;

    /**
     * @notice sets the new value of ltvDeviationBP
     * @param ltvDeviationBP new value of ltvDeviationBP
     */
    function setLtvDeviationBP(uint16 ltvDeviationBP) external;
}

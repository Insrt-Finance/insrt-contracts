// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';
import { IShardVaultView } from './IShardVaultView.sol';

/**
 * @title ShardVaultView facet containing view functions
 */
contract ShardVaultView is ShardVaultInternal, IShardVaultView {
    constructor(
        address shardCollection,
        address pUSD,
        address pETH,
        address punkMarket,
        address pusdCitadel,
        address pethCitadel,
        address lpFarm,
        address curvePUSDPool,
        address curvePETHPool,
        address booster,
        address marketplaceHelper,
        address jpeg
    )
        ShardVaultInternal(
            shardCollection,
            pUSD,
            pETH,
            punkMarket,
            pusdCitadel,
            pethCitadel,
            lpFarm,
            curvePUSDPool,
            curvePETHPool,
            booster,
            marketplaceHelper,
            jpeg
        )
    {}

    /**
     * @inheritdoc IShardVaultView
     */
    function totalSupply() external view returns (uint16) {
        return _totalSupply();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function maxSupply() external view returns (uint16) {
        return _maxSupply();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function shardValue() external view returns (uint256) {
        return _shardValue();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function shardCollection() external view returns (address) {
        return _shardCollection();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function count() external view returns (uint16) {
        return _count();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function formatTokenId(uint96 internalId)
        external
        view
        returns (uint256 tokenId)
    {
        tokenId = _formatTokenId(internalId);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function parseTokenId(uint256 tokenId)
        external
        pure
        returns (address vault, uint96 internalId)
    {
        (vault, internalId) = _parseTokenId(tokenId);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function isInvested() external view returns (bool) {
        return _isInvested();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function ownedTokenIds() external view returns (uint256[] memory ids) {
        ids = _ownedTokenIds();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function totalDebt(uint256 tokenId) external view returns (uint256 debt) {
        debt = _totalDebt(ShardVaultStorage.layout().jpegdVault, tokenId);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function accruedFees() external view returns (uint256 fees) {
        fees = _accruedFees();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function accruedJPEG() external view returns (uint256 jpeg) {
        _accruedJPEG();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function queryAutoCompForPUSD(uint256 pUSD)
        external
        view
        returns (uint256 autoComp)
    {
        autoComp = _queryAutoCompForPUSD(pUSD);
    }

    function queryAutoCompForPETH(uint256 pETH)
        external
        view
        returns (uint256 autoComp)
    {
        autoComp = _queryAutoCompForPETH(pETH);
    }

    function acquisitionFeeBP() external view returns (uint16 feeBP) {
        feeBP = _acquisitionFeeBP();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function saleFeeBP() external view returns (uint16 feeBP) {
        feeBP = _saleFeeBP();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function yieldFeeBP() external view returns (uint16 feeBP) {
        feeBP = _yieldFeeBP();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function maxUserShards() external view returns (uint16) {
        return _maxUserShards();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function shardBalances(address account) external view returns (uint16) {
        return _shardBalances(account);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function reservedShards() external view returns (uint16) {
        return _reservedShards();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function marketplaceHelper() external view returns (address) {
        return _marketplaceHelper();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function claimedJPS(uint256 shardId)
        external
        view
        returns (uint256 claimedJPS)
    {
        return _claimedJPS(shardId);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function claimedEPS(uint256 shardId)
        external
        view
        returns (uint256 claimedEPS)
    {
        return _claimedEPS(shardId);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function cumulativeJPS() external view returns (uint256 cumulativeJPS) {
        cumulativeJPS = _cumulativeJPS();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function cumulativeEPS() external view returns (uint256 cumulativeEPS) {
        cumulativeEPS = _cumulativeEPS();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function isYieldClaiming() external view returns (bool isYieldClaiming) {
        isYieldClaiming = _isYieldClaiming();
    }
}

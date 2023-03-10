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
        JPEGParams memory jpegParams,
        AuxiliaryParams memory auxiliaryParams
    ) ShardVaultInternal(jpegParams, auxiliaryParams) {}

    /**
     * @inheritdoc IShardVaultView
     */
    function maxSupply() external view returns (uint64) {
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
        jpeg = _accruedJPEG();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function queryAutoCompForPUSD(
        uint256 pUSD
    ) external view returns (uint256 autoComp) {
        autoComp = _queryAutoCompForPUSD(pUSD);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function queryAutoCompForPETH(
        uint256 pETH
    ) external view returns (uint256 autoComp) {
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
    function isAuthorized(
        address account
    ) external view returns (bool isAuthorized) {
        return _isAuthorized(account);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function maxMintBalance() external view returns (uint64) {
        return _maxMintBalance();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function reservedSupply() external view returns (uint64) {
        return _reservedSupply();
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
    function claimedJPEGPerShard(
        uint256 shardId
    ) external view returns (uint256 claimedJPEGPerShard) {
        claimedJPEGPerShard = _claimedJPEGPerShard(shardId);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function claimedETHPerShard(
        uint256 shardId
    ) external view returns (uint256 claimedETHPerShard) {
        claimedETHPerShard = _claimedETHPerShard(shardId);
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function cumulativeJPEGPerShard()
        external
        view
        returns (uint256 cumulativeJPEGPerShard)
    {
        cumulativeJPEGPerShard = _cumulativeJPEGPerShard();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function cumulativeETHPerShard()
        external
        view
        returns (uint256 cumulativeETHPerShard)
    {
        cumulativeETHPerShard = _cumulativeETHPerShard();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function isYieldClaiming() external view returns (bool isYieldClaiming) {
        isYieldClaiming = _isYieldClaiming();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function whitelistEndsAt() external view returns (uint48 whitelistEndsAt) {
        whitelistEndsAt = _whitelistEndsAt();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function treasury() external view returns (address treasury) {
        treasury = _treasury();
    }

    /**
     * @inheritdoc IShardVaultView
     */
    function isEnabled() external view returns (bool isEnabled) {
        isEnabled = _isEnabled();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultAdmin } from './IShardVaultAdmin.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';
import { IMarketPlaceHelper } from '../helpers/IMarketPlaceHelper.sol';

contract ShardVaultAdmin is ShardVaultInternal, IShardVaultAdmin {
    constructor(
        JPEGParams memory jpegParams,
        AuxiliaryParams memory auxiliaryParams
    ) ShardVaultInternal(jpegParams, auxiliaryParams) {}

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function purchasePunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId
    ) external payable onlyProtocolOwner {
        _purchasePunk(calls, punkId);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function collateralizePunkPUSD(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external onlyProtocolOwner returns (uint256 pUSD) {
        pUSD = _collateralizePunkPUSD(punkId, borrowAmount, insure);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function collateralizePunkPETH(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external onlyProtocolOwner returns (uint256 pETH) {
        pETH = _collateralizePunkPETH(punkId, borrowAmount, insure);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function stakePUSD(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) external onlyProtocolOwner returns (uint256 shares) {
        return _stakePUSD(amount, minCurveLP, poolInfoIndex);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function stakePETH(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) external onlyProtocolOwner returns (uint256 shares) {
        return _stakePETH(amount, minCurveLP, poolInfoIndex);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function investPunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId,
        uint256 borrowAmount,
        uint256 minCurveLP,
        uint256 poolInfoIndex,
        bool insure
    ) external onlyProtocolOwner {
        _investPunk(
            calls,
            punkId,
            borrowAmount,
            minCurveLP,
            poolInfoIndex,
            insure
        );
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setAcquisitionFee(uint16 feeBP) external onlyProtocolOwner {
        _setAcquisitionFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setSaleFee(uint16 feeBP) external onlyProtocolOwner {
        _setSaleFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setYieldFee(uint16 feeBP) external onlyProtocolOwner {
        _setYieldFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setMaxSupply(uint16 maxSupply) external onlyProtocolOwner {
        _setMaxSupply(maxSupply);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setWhitelistEndsAt(
        uint64 whitelistEndsAt
    ) external onlyProtocolOwner {
        _setWhitelistEndsAt(whitelistEndsAt);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setReservedShards(
        uint16 reservedShards
    ) external onlyProtocolOwner {
        _setReservedShards(reservedShards);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function unstakePUSD(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex
    ) external onlyProtocolOwner returns (uint256 pUSD) {
        pUSD = _unstakePUSD(amount, minPUSD, poolInfoIndex);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function unstakePETH(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex
    ) external onlyProtocolOwner returns (uint256 pETH) {
        pETH = _unstakePETH(amount, minPETH, poolInfoIndex);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setIsEnabled(bool isEnabled) external onlyProtocolOwner {
        _setIsEnabled(isEnabled);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function initiateWhitelistAndDeposits(
        uint64 whitelistEndsAt,
        uint16 reservedShards
    ) external onlyProtocolOwner {
        _setReservedShards(reservedShards);
        _setWhitelistEndsAt(whitelistEndsAt);
        _setIsEnabled(true);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function closePunkPosition(
        uint256 punkId,
        uint256 minTokenAmount,
        uint256 poolInfoIndex,
        bool isPUSD
    ) external onlyProtocolOwner {
        _closePunkPosition(punkId, minTokenAmount, poolInfoIndex, isPUSD);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setMaxUserShards(uint16 maxUserShards) external onlyProtocolOwner {
        _setMaxUserShards(maxUserShards);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function repayLoanPUSD(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 punkId
    ) external onlyProtocolOwner returns (uint256 paidDebt) {
        paidDebt = _repayLoanPUSD(amount, minPUSD, poolInfoIndex, punkId);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function repayLoanPETH(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex,
        uint256 punkId
    ) external onlyProtocolOwner returns (uint256 paidDebt) {
        paidDebt = _repayLoanPETH(amount, minPETH, poolInfoIndex, punkId);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function directRepayLoanPUSD(
        uint256 amount,
        uint256 punkId
    ) external onlyProtocolOwner {
        _directRepayLoan(PUSD, amount, punkId);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function directRepayLoanPETH(
        uint256 amount,
        uint256 punkId
    ) external onlyProtocolOwner {
        _directRepayLoan(PETH, amount, punkId);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function listPunk(
        IMarketPlaceHelper.EncodedCall[] memory calls,
        uint256 punkId
    ) external onlyProtocolOwner {
        _listPunk(calls, punkId);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function provideYieldPETH(
        uint256 autoComp,
        uint256 minETH,
        uint256 poolInfoIndex
    )
        external
        payable
        onlyProtocolOwner
        returns (uint256 providedETH, uint256 providedJPEG)
    {
        (providedETH, providedJPEG) = _provideYieldPETH(
            autoComp,
            minETH,
            poolInfoIndex
        );
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function makeUnusedETHClaimable() external onlyProtocolOwner {
        _makeUnusedETHClaimable();
    }
}

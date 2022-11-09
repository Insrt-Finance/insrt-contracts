// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultAdmin } from './IShardVaultAdmin.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';
import { IMarketPlaceHelper } from '../helpers/IMarketPlaceHelper.sol';

contract ShardVaultAdmin is ShardVaultInternal, IShardVaultAdmin {
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
        address marketplaceHelper
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
            marketplaceHelper
        )
    {}

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
    function closePunkPosition(
        uint256 punkId,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 ask
    ) external onlyProtocolOwner {
        _closePunkPosition(
            ShardVaultStorage.layout(),
            punkId,
            minPUSD,
            poolInfoIndex,
            ask
        );
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function downPayment(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 punkId
    ) external onlyProtocolOwner returns (uint256 paidDebt) {
        paidDebt = _downPayment(
            ShardVaultStorage.layout(),
            amount,
            minPUSD,
            poolInfoIndex,
            punkId
        );
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function pethDownPayment(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex,
        uint256 punkId
    ) external onlyProtocolOwner returns (uint256 paidDebt) {
        paidDebt = _pethDownPayment(
            ShardVaultStorage.layout(),
            amount,
            minPETH,
            poolInfoIndex,
            punkId
        );
    }
}

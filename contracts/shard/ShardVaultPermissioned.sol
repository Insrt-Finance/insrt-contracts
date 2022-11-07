// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultPermissioned } from './IShardVaultPermissioned.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

contract ShardVaultPermissioned is ShardVaultInternal, IShardVaultPermissioned {
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
     * @inheritdoc IShardVaultPermissioned
     */
    function purchasePunk(bytes calldata data, uint256 punkId)
        external
        payable
        onlyProtocolOwner
    {
        _purchasePunk(ShardVaultStorage.layout(), data, punkId);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function collateralizePunk(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external onlyProtocolOwner returns (uint256 pUSD) {
        pUSD = _collateralizePunk(
            ShardVaultStorage.layout(),
            punkId,
            borrowAmount,
            insure
        );
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function pethCollateralizePunk(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external onlyProtocolOwner returns (uint256 pETH) {
        pETH = _pethCollateralizePunk(
            ShardVaultStorage.layout(),
            punkId,
            borrowAmount,
            insure
        );
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function stake(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) external onlyProtocolOwner returns (uint256 shares) {
        return _stake(amount, minCurveLP, poolInfoIndex);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function pethStake(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) external onlyProtocolOwner returns (uint256 shares) {
        return _pethStake(amount, minCurveLP, poolInfoIndex);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function investPunk(
        bytes calldata data,
        uint256 punkId,
        uint256 borrowAmount,
        uint256 minCurveLP,
        uint256 poolInfoIndex,
        bool insure
    ) external onlyProtocolOwner {
        _investPunk(
            ShardVaultStorage.layout(),
            data,
            punkId,
            borrowAmount,
            minCurveLP,
            poolInfoIndex,
            insure
        );
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setAcquisitionFee(uint256 feeBP) external onlyProtocolOwner {
        _setAcquisitionFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setSaleFee(uint256 feeBP) external onlyProtocolOwner {
        _setSaleFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setYieldFee(uint256 feeBP) external onlyProtocolOwner {
        _setYieldFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setMaxSupply(uint256 maxSupply) external onlyProtocolOwner {
        _setMaxSupply(maxSupply);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function unstake(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex
    ) external onlyProtocolOwner returns (uint256 pUSD) {
        pUSD = _unstake(amount, minPUSD, poolInfoIndex);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function pethUnstake(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex
    ) external onlyProtocolOwner returns (uint256 pETH) {
        pETH = _pethUnstake(amount, minPETH, poolInfoIndex);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
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
     * @inheritdoc IShardVaultPermissioned
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
}

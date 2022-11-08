// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultAdmin } from './IShardVaultAdmin.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

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
    function purchasePunk(bytes calldata data, uint256 punkId)
        external
        payable
        onlyProtocolOwner
    {
        _purchasePunk(ShardVaultStorage.layout(), data, punkId);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function collateralizePunkPUSD(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external onlyProtocolOwner returns (uint256 pUSD) {
        pUSD = _collateralizePunkPUSD(
            ShardVaultStorage.layout(),
            punkId,
            borrowAmount,
            insure
        );
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function collateralizePunkPETH(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) external onlyProtocolOwner returns (uint256 pETH) {
        pETH = _collateralizePunkPETH(
            ShardVaultStorage.layout(),
            punkId,
            borrowAmount,
            insure
        );
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
     * @inheritdoc IShardVaultAdmin
     */
    function setAcquisitionFee(uint256 feeBP) external onlyProtocolOwner {
        _setAcquisitionFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setSaleFee(uint256 feeBP) external onlyProtocolOwner {
        _setSaleFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setYieldFee(uint256 feeBP) external onlyProtocolOwner {
        _setYieldFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultAdmin
     */
    function setMaxSupply(uint256 maxSupply) external onlyProtocolOwner {
        _setMaxSupply(maxSupply);
    }
}

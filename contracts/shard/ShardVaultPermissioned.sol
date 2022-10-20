// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultPermissioned } from './IShardVaultPermissioned.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

contract ShardVaultPermissioned is ShardVaultInternal, IShardVaultPermissioned {
    constructor(
        address shardCollection,
        address pUSD,
        address punkMarket,
        address citadel,
        address lpFarm,
        address curvePUSDPool,
        uint256 salesFeeBP,
        uint256 fundraiseFeeBP,
        uint256 yieldFeeBP
    )
        ShardVaultInternal(
            shardCollection,
            pUSD,
            punkMarket,
            citadel,
            lpFarm,
            curvePUSDPool,
            salesFeeBP,
            fundraiseFeeBP,
            yieldFeeBP
        )
    {}

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function purchasePunk(uint256 punkId) external payable onlyProtocolOwner {
        _purchasePunk(ShardVaultStorage.layout(), punkId);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function collateralizePunk(uint256 punkId, bool insure)
        external
        onlyProtocolOwner
    {
        _collateralizePunk(ShardVaultStorage.layout(), punkId, insure);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function stake(uint256 amount, uint256 minCurveLP)
        external
        onlyProtocolOwner
    {
        _stake(ShardVaultStorage.layout(), amount, minCurveLP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function investPunk(
        uint256 punkId,
        uint256 minCurveLP,
        bool insure
    ) external onlyProtocolOwner {
        _investPunk(ShardVaultStorage.layout(), punkId, minCurveLP, insure);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setFundraiseFee(uint256 feeBP) external onlyProtocolOwner {
        _setFundraiseFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setSalesFee(uint256 feeBP) external onlyProtocolOwner {
        _setSalesFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setYieldFee(uint256 feeBP) external onlyProtocolOwner {
        _setYieldFee(feeBP);
    }
}

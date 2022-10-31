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
        address marketHelper,
        uint256 interestBuffer,
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
            marketHelper,
            interestBuffer,
            salesFeeBP,
            fundraiseFeeBP,
            yieldFeeBP
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
    ) external onlyProtocolOwner {
        _collateralizePunk(
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
    ) external onlyProtocolOwner {
        _stake(amount, minCurveLP, poolInfoIndex);
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

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setMaxSupply(uint256 maxSupply) external onlyProtocolOwner {
        _setMaxSupply(maxSupply);
    }
}

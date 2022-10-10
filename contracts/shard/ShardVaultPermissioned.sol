// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultPermissioned } from './IShardVaultPermissioned.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

contract ShardVaultPermissioned is ShardVaultInternal, IShardVaultPermissioned {
    constructor(
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
    function purchasePunk(uint256 punkId) external payable {
        _onlyProtocolOwner();
        _purchasePunk(ShardVaultStorage.layout(), punkId);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function collateralizePunk(uint256 punkId, bool insure) external {
        _onlyProtocolOwner();
        _collateralizePunk(ShardVaultStorage.layout(), punkId, insure);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function stake(uint256 amount, uint256 minCurveLP) external {
        _onlyProtocolOwner();
        _stake(ShardVaultStorage.layout(), amount, minCurveLP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function investPunk(
        uint256 punkId,
        uint256 minCurveLP,
        bool insure
    ) external {
        _onlyProtocolOwner();
        _investPunk(ShardVaultStorage.layout(), punkId, minCurveLP, insure);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setFundraiseFee(uint256 feeBP) external {
        _onlyProtocolOwner();
        _setFundraiseFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setSalesFee(uint256 feeBP) external {
        _onlyProtocolOwner();
        _setSalesFee(feeBP);
    }

    /**
     * @inheritdoc IShardVaultPermissioned
     */
    function setYieldFee(uint256 feeBP) external {
        _onlyProtocolOwner();
        _setYieldFee(feeBP);
    }
}

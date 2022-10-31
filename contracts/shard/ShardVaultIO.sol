// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultIO } from './IShardVaultIO.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultIO is IShardVaultIO, ShardVaultInternal {
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
     * @inheritdoc IShardVaultIO
     */
    function deposit() external payable {
        _deposit();
    }

    /**
     * @inheritdoc IShardVaultIO
     */
    function withdraw(uint256[] memory tokenIds) external payable {
        _withdraw(tokenIds);
    }
}

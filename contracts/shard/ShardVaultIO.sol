// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultIO } from './IShardVaultIO.sol';
import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultIO is IShardVaultIO, ShardVaultInternal {
    constructor(
        address shardCollection,
        address pUSD,
        address pETH,
        address punkMarket,
        address pusdCitadel,
        address pusdLpFarm,
        address curvePUSDPool,
        address curvePETHPool,
        address convexPETHPool,
        address marketplaceHelper
    )
        ShardVaultInternal(
            shardCollection,
            pUSD,
            pETH,
            punkMarket,
            pusdCitadel,
            pusdLpFarm,
            curvePUSDPool,
            curvePETHPool,
            convexPETHPool,
            marketplaceHelper
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

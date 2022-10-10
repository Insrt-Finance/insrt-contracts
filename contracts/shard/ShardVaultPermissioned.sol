// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultPermissioned is ShardVaultInternal {
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
}

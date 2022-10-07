// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ShardVaultInternal } from './ShardVaultInternal.sol';

contract ShardVaultPermissioned is ShardVaultInternal {
    constructor(
        address pUSD,
        address punkMarket,
        address compounder,
        address lpFarm
    ) ShardVaultInternal(pUSD, punkMarket, compounder, lpFarm) {}
}

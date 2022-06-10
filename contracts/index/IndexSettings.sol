// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IVault } from '../balancer/IVault.sol';
import { IndexInternal } from './IndexInternal.sol';

contract IndexSettings is IndexInternal {
    constructor(address balancerVault, address balancerHelpers)
        IndexInternal(balancerVault, balancerHelpers)
    {}
}

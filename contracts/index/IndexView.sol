// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IIndexView } from './IIndexView.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IBalancerHelpers } from '../balancer/IBalancerHelpers.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IVault, IAsset } from '../balancer/IVault.sol';

/**
 * @title Infra Index view functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexView is IndexInternal, IIndexView {
    using IndexStorage for IndexStorage.Layout;

    constructor(address balancerVault, address balancerHelpers)
        IndexInternal(balancerVault, balancerHelpers)
    {}

    /**
     * @inheritdoc IIndexView
     */
    function getPoolId() external view returns (bytes32) {
        return _poolId();
    }

    /**
     * @inheritdoc IIndexView
     */
    function getExitFee() external view returns (uint16) {
        return _exitFee();
    }
}

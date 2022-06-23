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

    constructor(
        address balancerVault,
        address balancerHelpers,
        address swapper,
        uint256 exitFee
    ) IndexInternal(balancerVault, balancerHelpers, swapper, exitFee) {}

    /**
     * @inheritdoc IIndexView
     */
    function getPoolId() external view returns (bytes32) {
        return _poolId();
    }

    /**
     * @inheritdoc IIndexView
     */
    function exitFee() external view returns (uint256) {
        return _exitFee();
    }
}

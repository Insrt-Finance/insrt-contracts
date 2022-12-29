// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';

import { IBalancerHelpers } from '../interfaces/balancer/IBalancerHelpers.sol';
import { IInvestmentPool } from '../interfaces/balancer/IInvestmentPool.sol';
import { IVault, IAsset } from '../interfaces/balancer/IVault.sol';
import { IIndexView } from './IIndexView.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';

/**
 * @title Infra Index view functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexView is IndexInternal, IIndexView {
    using ABDKMath64x64 for int128;
    using IndexStorage for IndexStorage.Layout;

    constructor(
        address balancerVault,
        address balancerHelpers,
        address swapper,
        uint256 exitFeeBP,
        uint256 streamingFeeBP
    )
        IndexInternal(
            balancerVault,
            balancerHelpers,
            swapper,
            exitFeeBP,
            streamingFeeBP
        )
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
    function exitFee() external view returns (uint256) {
        return BASIS - EXIT_FEE_FACTOR_64x64.mulu(BASIS);
    }

    /**
     * @inheritdoc IIndexView
     */
    function feesAccrued() external view returns (uint256) {
        return _feesAccrued();
    }
}

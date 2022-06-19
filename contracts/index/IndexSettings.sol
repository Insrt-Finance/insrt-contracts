// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IVault } from '../balancer/IVault.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IIndexSettings } from './IIndexSettings.sol';

/**
 * @title IndexSettings functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexSettings is IndexInternal, IIndexSettings {
    constructor(
        address balancerVault,
        address balancerHelpers,
        address swapper,
        uint256 exitFee
    ) IndexInternal(balancerVault, balancerHelpers, swapper, exitFee) {}

    /**
     * @inheritdoc IIndexSettings
     */
    function updateWeights(uint256[] calldata updatedWeights, uint256 endTime)
        external
        onlyProtocolOwner
    {
        (address investmentPool, ) = IVault(BALANCER_VAULT).getPool(_poolId());
        IInvestmentPool(investmentPool).updateWeightsGradually(
            block.timestamp,
            endTime,
            updatedWeights
        );
    }

    /**
     * @inheritdoc IIndexSettings
     */
    function setSwapPause(bool swapEnabled) external onlyProtocolOwner {
        (address investmentPool, ) = IVault(BALANCER_VAULT).getPool(_poolId());
        IInvestmentPool(investmentPool).setSwapEnabled(swapEnabled);
    }
}

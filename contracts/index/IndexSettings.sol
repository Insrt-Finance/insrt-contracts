// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IVault } from '../balancer/IVault.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IIndexSettings } from './IIndexSettings.sol';
import { IndexStorage } from './IndexStorage.sol';

/**
 * @title IndexSettings functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexSettings is IndexInternal, IIndexSettings {
    using SafeERC20 for IERC20;

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
    function setSwapEnabled(bool swapEnabled) external onlyProtocolOwner {
        (address investmentPool, ) = IVault(BALANCER_VAULT).getPool(_poolId());
        IInvestmentPool(investmentPool).setSwapEnabled(swapEnabled);
    }

    /**
     * @inheritdoc IIndexSettings
     */
    function withdrawAllLiquidity() external onlyProtocolOwner {
        address asset = _asset();
        IERC20(asset).safeTransfer(
            msg.sender,
            IERC20(asset).balanceOf(address(this))
        );
    }
}

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
    function queryUserDepositExactInForAnyOut(
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) external returns (uint256 bptOut, uint256[] memory amountsIn) {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructJoinExactInRequest(
            l,
            amounts,
            minBPTAmountOut
        );

        (bptOut, amountsIn) = IBalancerHelpers(BALANCER_HELPERS).queryJoin(
            l.poolId,
            address(this),
            address(this),
            request
        );
    }

    //TODO: Query exact out withdraw
    /**
     * @inheritdoc IIndexView
     */
    function queryUserWithdrawExactForAll(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external returns (uint256 bptIn, uint256[] memory amountsOut) {
        IndexStorage.Layout storage l = IndexStorage.layout();

        IVault.ExitPoolRequest
            memory request = _constructExitExactForAllRequest(
                l,
                sharesOut,
                minAmountsOut
            );

        (bptIn, amountsOut) = IBalancerHelpers(BALANCER_HELPERS).queryExit(
            l.poolId,
            address(this),
            msg.sender,
            request
        );
    }

    /**
     * @inheritdoc IIndexView
     */
    function queryUserWithdrawExactForSingle(
        uint256 sharesOut,
        uint256[] memory minAmountsOut,
        uint256 tokenId
    ) external returns (uint256 bptIn, uint256[] memory amountsOut) {
        IndexStorage.Layout storage l = IndexStorage.layout();

        IVault.ExitPoolRequest
            memory request = _constructExitExactForSingleRequest(
                l,
                minAmountsOut,
                sharesOut,
                tokenId
            );

        (bptIn, amountsOut) = IBalancerHelpers(BALANCER_HELPERS).queryExit(
            l.poolId,
            address(this),
            msg.sender,
            request
        );
    }

    /**
     * @inheritdoc IIndexView
     */
    function getPoolId() external view returns (bytes32) {
        return _poolId();
    }

    /**
     * @inheritdoc IIndexView
     */
    function getPool() external view returns (address poolAddress) {
        (poolAddress, ) = IVault(BALANCER_VAULT).getPool(
            IndexStorage.layout().poolId
        );
    }
}

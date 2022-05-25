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

    /**
     * @inheritdoc IIndexView
     */
    function queryUserDepositSingleForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut,
        uint256 tokenIndex
    ) external returns (uint256 bptOut, uint256[] memory amountsIn) {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest
            memory request = _constructJoinSingleForExactRequest(
                l,
                amounts,
                bptAmountOut,
                tokenIndex
            );

        (bptOut, amountsIn) = IBalancerHelpers(BALANCER_HELPERS).queryJoin(
            l.poolId,
            address(this),
            address(this),
            request
        );
    }

    /**
     * @inheritdoc IIndexView
     */
    function queryUserDepositAllForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut
    ) external returns (uint256 bptOut, uint256[] memory amountsIn) {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest
            memory request = _constructJoinAllForExactRequest(
                l,
                amounts,
                bptAmountOut
            );

        (bptOut, amountsIn) = IBalancerHelpers(BALANCER_HELPERS).queryJoin(
            l.poolId,
            address(this),
            address(this),
            request
        );
    }

    //TODO: Query other withdraws
    //TODO: Modify name
    /**
     * @notice function to return the amounts return for a certain BPT, and the BPT expected in for those amounts
     * @param sharesOut the amount of insrt-index shares a user wants to redeem
     * @param minAmountsOut the minimum amount of each token the user is willing to accept
     * @return bptIn the amount of BPT required for the amounts out
     * @return amountsOut the amount of each token returned for the BPT
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
}

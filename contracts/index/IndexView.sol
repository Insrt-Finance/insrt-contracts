// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IBalancerHelpers } from '../balancer/IBalancerHelpers.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IVault, IAsset } from '../balancer/IVault.sol';

contract IndexView is IndexInternal {
    using IndexStorage for IndexStorage.Layout;

    constructor(address balancerVault, address balancerHelpers)
        IndexInternal(balancerVault, balancerHelpers)
    {}

    //TODO: Query other deposits
    //TODO: Modify name
    /**
     * @notice function to return the BPT given for a certain amount of underlying Balancer InvesmentPool tokens
     * @param amounts an array comprised of the amount of each underlying token
     * @param minBPTAmountOut the minimum amount of BPT accepted as a return
     * @return bptOut the BPT returned
     * @return amountsIn the amounts to be taken in by Balancer InvestmentPool for the BPT returned
     */
    function queryUserDepositExactIn(
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

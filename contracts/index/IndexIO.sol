// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

import { IIndexIO } from './IIndexIO.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IVault } from '../balancer/IVault.sol';

/**
 * @title Infra Index Input-Output functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexIO is IndexInternal, IIndexIO {
    using IndexStorage for IndexStorage.Layout;

    constructor(address balancerVault, address balancerHelpers)
        IndexInternal(balancerVault, balancerHelpers)
    {}

    /**
     * @inheritdoc IIndexIO
     */
    function initializePoolByDeposit(
        uint256[] memory amountsIn,
        uint256 amountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructJoinInitRequest(
            l,
            amountsIn
        );

        //TODO: perhaps amountOut may be set to 0 in this case?
        _performJoinAndMint(amountOut, l.poolId, request);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userDepositExactInForAnyOut(
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructJoinExactInRequest(
            l,
            amounts,
            minBPTAmountOut
        );

        _performJoinAndMint(minBPTAmountOut, l.poolId, request);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userDepositSingleForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut,
        uint256 tokenIndex
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructJoinSingleForExactRequest(
            l,
            amounts, //could perhaps be an empty array? Balancer will request the appropriate amount
            bptAmountOut,
            tokenIndex
        );

        _performJoinAndMint(bptAmountOut, l.poolId, request);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userDepositAllForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest
            memory request = _constructJoinAllForExactRequest(
                l,
                amounts,
                bptAmountOut
            );

        _performJoinAndMint(bptAmountOut, l.poolId, request);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userWithdrawExactForAll(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.ExitPoolRequest
            memory request = _constructExitExactForAllRequest(
                l,
                sharesOut,
                minAmountsOut
            );

        _performExitAndWithdraw(sharesOut, l.poolId, request);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userWithdrawExactForSingle(
        uint256 sharesOut,
        uint256[] memory amountsOut,
        uint256 tokenId
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.ExitPoolRequest
            memory request = _constructExitExactForSingleRequest(
                l,
                amountsOut,
                sharesOut,
                tokenId
            );

        _performExitAndWithdraw(sharesOut, l.poolId, request);
    }

    //TODO: Still WIP to identify how to apply a fee.
    function userWithdrawExactOut(
        uint256 maxSharesIn,
        uint256[] memory minAmountsOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        uint256 sharesOut; //NOTE: STILL NEEDS TO BE IDENTIFIED.
        IVault.ExitPoolRequest memory request = _constructExitExactOutRequest(
            l,
            minAmountsOut,
            maxSharesIn
        );

        _performExitAndWithdraw(sharesOut, l.poolId, request);
    }
}

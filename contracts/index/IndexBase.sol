// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC4626 } from '@solidstate/contracts/token/ERC4626/ERC4626.sol';
import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';

import { IIndexBase } from './IIndexBase.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IVault, IAsset } from '../balancer/IVault.sol';
import { IBalancerHelpers } from '../balancer/IBalancerHelpers.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';

/**
 * @title Infra Index base functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexBase is IIndexBase, ERC4626, IndexInternal {
    using IndexStorage for IndexStorage.Layout;

    constructor(address balancerVault, address balancerHelpers)
        IndexInternal(balancerVault, balancerHelpers)
    {}

    /**
     * @inheritdoc IndexInternal
     */
    function _name()
        internal
        view
        override(ERC20MetadataInternal, IndexInternal)
        returns (string memory)
    {
        return super._name();
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _symbol()
        internal
        view
        override(ERC20MetadataInternal, IndexInternal)
        returns (string memory)
    {
        return super._symbol();
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _decimals()
        internal
        pure
        override(ERC20MetadataInternal, IndexInternal)
        returns (uint8)
    {
        return super._decimals();
    }

    /**
     * @notice function to deposit an amount of tokens to Balancer InvestmentPool
     * @dev takes all investmentPool tokens at specified amounts, deposits
     * into InvestmentPool, receives BPT in exchange to store in insrt-index,
     * returns insrt-index shares to user
     * @param amounts the amounts of underlying tokens in balancer investmentPool
     * @param minBPTAmountOut the minimum amount of BPT expected to be given back
     */
    function userDepositAmounts(
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructDepositAmountsRequest(
            l,
            amounts,
            minBPTAmountOut
        );
        if (
            !IVault(BALANCER_VAULT).hasApprovedRelayer(
                msg.sender,
                address(this)
            )
        ) {
            //Note: https://github.com/balancer-labs/balancer-v2-monorepo/blob/9eb179da66c4f47c795b7b86479c3f13411c027d/pkg/vault/contracts/VaultAuthorization.sol#L116
            IVault(BALANCER_VAULT).setRelayerApproval(
                msg.sender,
                address(this),
                true
            );
        }

        //TODO: Is there a potential mismatch of results between queryJoin and joinPool?
        //Remove amountsIn declaration?
        (uint256 bptOut, uint256[] memory amountsIn) = IBalancerHelpers(
            BALANCER_HELPERS
        ).queryJoin(l.poolId, address(this), address(this), request);

        //TODO: InternalBalance implications
        IVault(BALANCER_VAULT).joinPool(
            l.poolId,
            address(this),
            address(this),
            request
        );

        //Mint shares to joining user
        _mint(bptOut, msg.sender);
    }

    /**
     * @notice function which burns insrt-index shares and returns underlying tokens in Balancer InvestmentPool
     * @dev applies a fee on the shares, and sends an amount of `remainingShares` of BPT from insrt-index
     * to Balancer InvestmentPool in exchange for tokens, sent to the user. Shares are burnt.
     * @param sharesOut the amount of shares the user wishes to withdraw
     */
    function userWithdrawAmount(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.ExitPoolRequest memory request = _constructWithdrawAmountRequest(
            l,
            sharesOut,
            minAmountsOut
        );

        IVault(BALANCER_VAULT).exitPool(
            l.poolId,
            msg.sender,
            payable(address(this)),
            request
        );

        //User withdraw and burn shares for exiting user.
        _withdraw(sharesOut, msg.sender, msg.sender);
    }

    /**
     * @notice function to return the BPT given for a certain amount of underlying Balancer InvesmentPool tokens
     * @param amounts an array comprised of the amount of each underlying token
     * @param minBPTAmountOut the minimum amount of BPT accepted as a return
     * @return bptOut the BPT returned
     * @return amountsIn the amounts to be taken in by Balancer InvestmentPool for the BPT returned
     */
    function queryUserDepositAmounts(
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) external returns (uint256 bptOut, uint256[] memory amountsIn) {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest memory request = _constructDepositAmountsRequest(
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
     * @notice function to return the amounts return for a certain BPT, and the BPT expected in for those amounts
     * @param sharesOut the amount of insrt-index shares a user wants to redeem
     * @param minAmountsOut the minimum amount of each token the user is willing to accept
     * @return bptIn the amount of BPT required for the amounts out
     * @return amountsOut the amount of each token returned for the BPT
     */
    function queryUserWithdraw(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external returns (uint256 bptIn, uint256[] memory amountsOut) {
        IndexStorage.Layout storage l = IndexStorage.layout();

        IVault.ExitPoolRequest memory request = _constructWithdrawAmountRequest(
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
     * @notice function to construct the request needed for a user to deposit in an insrt-index
     * @dev only works for JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT
     * @param l the index layout
     * @param amounts an array comprised of the amount of each underlying token
     * @param minBPTAmountOut the minimum amount of BPT accepted as a return
     * @return request a JoinPoolRequest constructed for EXACT_TOKENS_IN_FOR_BPT_OUT JoinKind
     */
    function _constructDepositAmountsRequest(
        IndexStorage.Layout storage l,
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) internal view returns (IVault.JoinPoolRequest memory request) {
        IInvestmentPool.JoinKind kind = IInvestmentPool
            .JoinKind
            .EXACT_TOKENS_IN_FOR_BPT_OUT;
        //To perform an Join of kind `EXACT_TOKENS_IN_FOR_BPT_OUT` the `userData` variable
        //must contain the encoded "kind" of join, and the amounts of tokens given for the joins, and
        //the minBPTAmountOut.
        //Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/d2794ef7d8f6d321cde36b7c536e8d51971688bd/pkg/interfaces/contracts/pool-weighted/WeightedPoolUserData.sol#L49
        bytes memory userData = abi.encode(kind, amounts, minBPTAmountOut);

        request.assets = _tokensToAssets(l.tokens); //perhaps this function is needless if tokens are saved in storage as assets (called in constructor)
        request.maxAmountsIn = amounts;
        request.userData = userData;
        request.fromInternalBalance = false; // Implications?
    }

    /**
     * @notice function to construct the request needed for a user to redeem a certain amount of insrt-index shares
     * @dev only works for ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT
     * @param sharesOut the amount of insrt-index shares a user wants to redeem
     * @param minAmountsOut the minimum amount of each token the user is willing to accept
     * @return request an ExitPoolRequest constructed for EXACT_BPT_IN_FOR_TOKENS_OUT ExitKind
     */
    function _constructWithdrawAmountRequest(
        IndexStorage.Layout storage l,
        uint256 sharesOut,
        uint256[] memory minAmountsOut
    ) internal view returns (IVault.ExitPoolRequest memory request) {
        //Maybe this should be accounted for somewhere? Automatically done by balanceOf bpt tokens?
        (uint256 feeBpt, uint256 remainingSharesOut) = _applyFee(
            l.exitFee,
            sharesOut
        );
        IInvestmentPool.ExitKind kind = IInvestmentPool
            .ExitKind
            .EXACT_BPT_IN_FOR_TOKENS_OUT;
        //To perform an Exit of kind `EXACT_BPT_IN_FOR_TOKENS_OUT` the `userData` variable
        //must contain the encoded "kind" of exit, and the amount of BPT to "exit" from the
        //pool.
        bytes memory userData = abi.encode(kind, remainingSharesOut);

        request.assets = _tokensToAssets(l.tokens);
        request.minAmountsOut = minAmountsOut;
        request.userData = userData;
        //Internal balance is set to false so tokens can be transferred to the user.
        //Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/a9b1e969a19c4f93c14cd19fba45aaa25b015d12/pkg/vault/contracts/interfaces/IVault.sol#L410
        request.toInternalBalance = false;
    }
}

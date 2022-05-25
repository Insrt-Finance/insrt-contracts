// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Infra Index Input Output Interface
 */
interface IIndexIO {
    /**
     * @notice function to initiliaze the Balancer InvestmentPool
     * @dev required to be called once otherwise all other deposits will be reverted
     * Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/823f7fe7d3cb45f9bc6bcdfb83af3d70c050d1d2/pkg/pool-utils/contracts/BasePool.sol#L220
     * @param amountsIn the amounts of each token deposited
     * @param amountOut the amount of BPT expected to be received as a minimum
     */
    function initializePoolByDeposit(
        uint256[] memory amountsIn,
        uint256 amountOut
    ) external;

    /**
     * @notice function to deposit an amount of tokens to Balancer InvestmentPool
     * @dev takes all investmentPool tokens at specified amounts, deposits
     * into InvestmentPool, receives BPT in exchange to store in insrt-index,
     * returns insrt-index shares to user
     * @param amounts the amounts of underlying tokens in balancer investmentPool
     * @param minBPTAmountOut the minimum amount of BPT expected to be given back
     */
    function userDepositExactInForAnyOut(
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) external;

    /**
     * @notice function to deposit a single token for shares in the Insrt-index
     * @dev takes a single investment pool token from the user, deposits into investment pool,
     * Insrt-index receives an exact (known) amount of BPT in exchange, user receives insrt-index
     * shares proportionally.
     * @param amounts the amounts of underlying tokens in Balancer InvestmentPool deposited -
     * could be a single token however call requests []
     * @param bptAmountOut the exact amount of BPT wanted by the user (translated to Insrt-index shares)
     * @param tokenIndex the index of the deposited token in the array of Assets.
     */
    function userDepositSingleForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut,
        uint256 tokenIndex
    ) external;

    /**
     * @notice function to deposit any required amount of all tokens to receive an exact amount of
     * Insrt-index shares
     * @dev takes all investment pool tokens from the user, deposits into investment pool,
     * Insrt-index receives an exact (known) amount of BPT in exchange, user receives insrt-index
     * shares proportionally.
     * @param amounts the amounts of underlying tokens in Balancer InvestmentPool deposited
     * @param bptAmountOut the exact amount of BPT (Insrt-index) shares requested
     */
    function userDepositAllForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut
    ) external;

    /**
     * @notice function which burns insrt-index shares and returns underlying tokens in Balancer InvestmentPool
     * @dev applies a fee on the shares, and sends an amount of `remainingShares` of BPT from insrt-index
     * to Balancer InvestmentPool in exchange for tokens, sent to the user. Shares are burnt.
     * @param sharesOut the amount of shares the user wishes to withdraw
     * @param minAmountsOut the minimum amounts of tokens received for the withdraw
     */
    function userWithdrawExactForAll(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external;

    /**
     * @notice function to withdraw Insrt-shares for a single underlying token
     * @dev applies a fee on the shares withdrawn, and sends an amount of `remainingSahres` of BPT from
     * insrt-index to Balancer Investment pool in exchange for the single token, send to user. Shares are burnt.
     * @param sharesOut the amount of shares the user wishes to withdraw
     * @param amountsOut the amounts of underlying token received in exchange for shares
     * @param tokenId the id of the token to be received
     */
    function userWithdrawExactForSingle(
        uint256 sharesOut,
        uint256[] memory amountsOut,
        uint256 tokenId
    ) external;

    //missing until refined
    function userWithdrawExactOut(
        uint256 maxSharesIn,
        uint256[] memory minAmountsOut
    ) external;
}

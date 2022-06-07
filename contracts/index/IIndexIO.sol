// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Infra Index Input Output Interface
 */
interface IIndexIO {
    /**
     * @notice initialize the Balancer InvestmentPool
     * @dev internal Balancer call will revert if called more than once
     * @param amounts the amounts of each token deposited
     * @param beneficiary recipient of initial BPT supply
     */
    function initialize(uint256[] memory amounts, address beneficiary) external;

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
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Infra Index Input Output Interface
 */
interface IIndexIO {
    /**
     * @notice initialize the Balancer InvestmentPool
     * @dev internal Balancer call will revert if called more than once
     * @param poolTokenAmounts the amounts of each token deposited
     * @param receiver recipient of initial BPT supply
     */
    function initialize(uint256[] memory poolTokenAmounts, address receiver)
        external;

    /**
     * @notice function to deposit an amount of tokens to Balancer InvestmentPool
     * @dev takes all investmentPool tokens at specified amounts, deposits
     * into InvestmentPool, receives BPT in exchange to store in insrt-index,
     * returns insrt-index shares to user
     * @param poolTokenAmounts the amounts of underlying tokens in balancer investmentPool
     * @param minAssetAmount the minimum amount of BPT expected to be given back
     * @param receiver recipient of minted Index shares
     * @return shareAmount quantity of shares to mint
     */
    function deposit(
        uint256[] memory poolTokenAmounts,
        uint256 minAssetAmount,
        address receiver
    ) external returns (uint256 shareAmount);

    /**
     * @notice function which burns insrt-index shares and returns underlying tokens in Balancer InvestmentPool
     * @dev applies a fee on the shares, and sends an amount of `remainingShares` of BPT from insrt-index
     * to Balancer InvestmentPool in exchange for tokens, sent to the user. Shares are burnt.
     * @param shareAmount quantity of Index shares to redeem
     * @param minPoolTokenAmounts the minimum amounts of pool tokens received for the withdraw
     * @param receiver recipient of withdrawn pool tokens
     * @return poolTokenAmounts quantities of underlying pool tokens yielded
     */
    function redeem(
        uint256 shareAmount,
        uint256[] calldata minPoolTokenAmounts,
        address receiver
    ) external returns (uint256[] memory poolTokenAmounts);

    /**
     * @notice function to withdraw Insrt-shares for a single underlying token
     * @dev applies a fee on the shares withdrawn, and sends an amount of `remainingSahres` of BPT from
     * insrt-index to Balancer Investment pool in exchange for the single token, send to user. Shares are burnt.
     * @param shareAmount quantity of Index shares to redeem
     * @param minPoolTokenAmounts the amounts of underlying token received in exchange for shares
     * @param tokenId the id of the token to be received
     * @param receiver recipient of withdrawn pool tokens
     * @return poolTokenAmounts quantities of underlying pool tokens yielded
     */
    function redeem(
        uint256 shareAmount,
        uint256[] memory minPoolTokenAmounts,
        uint256 tokenId,
        address receiver
    ) external returns (uint256[] memory poolTokenAmounts);
}

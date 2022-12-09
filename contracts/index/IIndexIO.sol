// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Infra Index Input Output Interface
 */
interface IIndexIO {
    /**
     * @notice initialize the Balancer InvestmentPool
     * @dev internal Balancer call will revert if called more than once
     * @param poolTokenAmounts quantities of underlying pool tokens deposited
     * @param receiver recipient of initial BPT supply
     */
    function initialize(
        uint256[] memory poolTokenAmounts,
        address receiver
    ) external;

    /**
     * @notice trigger collection of accrued streaming from given addresses
     * @param accounts addresses whose fees to collect
     */
    function collectStreamingFees(address[] calldata accounts) external;

    /**
     * @notice function to deposit an amount of tokens to Balancer InvestmentPool
     * @dev takes all investmentPool tokens at specified amounts, deposits
     * into InvestmentPool, receives BPT in exchange to store in insrt-index,
     * returns insrt-index shares to user
     * @param poolTokenAmounts quantities of underlying pool tokens deposited
     * @param minShareAmount the minimum acceptable number of shares to be minted
     * @param receiver recipient of minted Index shares
     * @return shareAmount quantity of shares to mint
     */
    function deposit(
        uint256[] memory poolTokenAmounts,
        uint256 minShareAmount,
        address receiver
    ) external returns (uint256 shareAmount);

    /**
     * @notice performs an arbitrary swap of an ERC20 token for an underlying token of the Insrt-Index, deposit underlying token
     *  into the Insrt-Index
     * @dev takes a desired ERC20 input token, swaps it for an underlying outputToken which
     * is an underlying token of Insrt-Index and deposits it, returning Insrt-Index shares to
     * user
     * @param inputToken the desired ERC20 to deposit
     * @param inputTokenAmount the amount of inputToken to be deposited
     * @param outputToken an underlying token of the Insrt-Index and the token to be swapped to
     * @param outputTokenAmountMin the minimum amount of returned output token after the swap
     * @param outputTokenIndex the index of the outputToken in the tokens array in storage layout
     * @param minShareAmount the minimum amount of shares Insrt-Index to be received by the user
     * @param target the address of the contract to perform the swapping
     * @param data the calldata to execute in the low-level call
     * @param receiver the address of the user receiving the shares
     * @return shareAmount the amount of shares returned for the deposit
     */
    function deposit(
        address inputToken,
        uint256 inputTokenAmount,
        address outputToken,
        uint256 outputTokenAmountMin,
        uint256 outputTokenIndex,
        uint256 minShareAmount,
        address target,
        bytes calldata data,
        address receiver
    ) external returns (uint256 shareAmount);

    /**
     * @notice function which burns insrt-index shares and returns underlying tokens in Balancer InvestmentPool
     * @dev applies a fee on the shares, and sends an amount of `remainingShares` of BPT from insrt-index
     * to Balancer InvestmentPool in exchange for tokens, sent to the user. Shares are burnt.
     * @param shareAmount quantity of Index shares to redeem
     * @param minPoolTokenAmounts the minimum amounts of pool tokens received for the withdraw
     * @param receiver recipient of withdrawn pool tokens
     * @return assetAmount the amount of underlying asset returned for redeemed shares
     * @return poolTokenAmounts quantities of underlying pool tokens yielded
     */
    function redeem(
        uint256 shareAmount,
        uint256[] calldata minPoolTokenAmounts,
        address receiver
    ) external returns (uint256 assetAmount, uint256[] memory poolTokenAmounts);

    /**
     * @notice function to withdraw Insrt-shares for a single underlying token
     * @dev applies a fee on the shares withdrawn, and sends an amount of `remainingSahres` of BPT from
     * insrt-index to Balancer Investment pool in exchange for the single token, send to user. Shares are burnt.
     * @param shareAmount quantity of Index shares to redeem
     * @param minPoolTokenAmounts minimum quantities of underlying pool tokens yielded
     * @param tokenId the id of the token to be received
     * @param receiver recipient of withdrawn pool tokens
     * @return assetAmount the amount of underlying asset returned for redeemed shares
     * @return poolTokenAmount quantitiy of underlying pool token with tokenId returned
     */
    function redeem(
        uint256 shareAmount,
        uint256[] memory minPoolTokenAmounts,
        uint256 tokenId,
        address receiver
    ) external returns (uint256 assetAmount, uint256 poolTokenAmount);
}

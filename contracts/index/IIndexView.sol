// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Infra Index View Interface
 */
interface IIndexView {
    /**
     * @notice function to return the BPT given for a certain amount of underlying Balancer InvesmentPool tokens
     * @dev particular to JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT
     * @param amounts an array comprised of the amounts of each underlying token deposited
     * @param minBPTAmountOut the minimum amount of BPT accepted as a return
     * @return bptOut the BPT returned
     * @return amountsIn the amounts to be taken in by Balancer InvestmentPool for the BPT returned
     */
    function queryUserDepositExactInForAnyOut(
        uint256[] memory amounts,
        uint256 minBPTAmountOut
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    /**
     * @notice function to return the BPT given for a certain amount of underlying Balancer InvesmentPool tokens
     * @dev particular to JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT
     * @param amounts an array comprised of the amounts of each underlying token deposited
     * @param bptAmountOut the minimum amount of BPT accepted as a return
     * @param tokenIndex the index of the deposited underlying token
     * @return bptOut the BPT returned
     * @return amountsIn the amounts to be taken in by Balancer InvestmentPool for the BPT returned
     */
    function queryUserDepositSingleForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut,
        uint256 tokenIndex
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    /**
     * @notice function to return the BPT given for a certain amount of underlying Balancer InvesmentPool tokens
     * @dev particular to JoinKind.ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
     * @param amounts an array comprised of the amounts of each underlying token deposited
     * @param bptAmountOut the minimum amount of BPT accepted as a return
     * @return bptOut the BPT returned
     * @return amountsIn the amounts to be taken in by Balancer InvestmentPool for the BPT returned
     */
    function queryUserDepositAllForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    /**
     * @notice function to return the amounts return for a certain BPT, and the BPT expected in for those amounts
     * @dev specific to ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT
     * @param sharesOut the amount of insrt-index shares a user wants to redeem
     * @param minAmountsOut the minimum amount of each token the user is willing to accept
     * @return bptIn the amount of BPT required for the amounts out
     * @return amountsOut the amount of each token returned for the BPT
     */
    function queryUserWithdrawExactForAll(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);

    /**
     * @notice function to return the amounts return for a certain BPT, and the BPT expected in for those amounts
     * @dev specific to ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT
     * @param sharesOut the amount of insrt-index shares a user wants to redeem
     * @param minAmountsOut the minimum amount of each token the user is willing to accept
     * @param tokenId the id of the underlying token which is requested
     * @return bptIn the amount of BPT required for the amounts out
     * @return amountsOut the amount of each token returned for the BPT
     */
    function queryUserWithdrawExactForSingle(
        uint256 sharesOut,
        uint256[] memory minAmountsOut,
        uint256 tokenId
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);

    /**
     * @notice function to return the id of the Balancer Investment Pool corresponding to a target index
     * @dev useful for querying properties of the Investment Pool underlying the index
     * @return poolId
     */
    function getPoolId() external view returns (bytes32);
}

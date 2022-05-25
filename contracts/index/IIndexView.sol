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
}

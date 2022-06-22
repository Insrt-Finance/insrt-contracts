// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface for swapping helper
 */
interface ISwapper {
    /**
     * @notice execute an arbitrary swap on an arbitrary target
     * @param inputToken the token to be given for the swap
     * @param inputTokenAmount the amount of the token to be given for the swap
     * @param outputToken the expected token to be received after the swap
     * @param outputTokenAmountMin the minimum amount of outputToken to be received from the swap
     * @param target the address of the contract to perform the swap
     * @param receiver the receiver of the output of the swap
     * @param data the calldata required for the swap
     * @return outputAmount the outputToken amount returned by the swap
     */
    function swap(
        address inputToken,
        uint256 inputTokenAmount,
        address outputToken,
        uint256 outputTokenAmountMin,
        address target,
        address receiver,
        bytes calldata data
    ) external returns (uint256 outputAmount);
}

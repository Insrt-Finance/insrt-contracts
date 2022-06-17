// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface for swapping helper
 */
interface ISwapper {
    /**
     * @notice function to execute an arbitrary swap on an arbitrary target
     * @param outputToken the expected token to be received after the swap
     * @param outputTokenAmountMin the minimum amount of outputToken to be received from the swap
     * @param target the address of the contract to perform the swap
     * @param data the calldata required for the swap
     */
    function swap(
        address outputToken,
        uint256 outputTokenAmountMin,
        address target,
        bytes calldata data
    ) external;
}

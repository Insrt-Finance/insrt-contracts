// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Interface for Index Settings functions
 */
interface IIndexSettings {
    /**
     * @notice function to update the weights of each underlying token in the Insrt Index
     * @param updatedWeights the updated values of the token weights
     * @param endTime the timestamp by which the weights should have changed to their new values
     */
    function updateWeights(uint256[] calldata updatedWeights, uint256 endTime)
        external;
}

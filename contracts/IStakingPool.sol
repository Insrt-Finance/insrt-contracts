// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IStakingPool {
    /**
     * @notice function for a user to deposit an amount of product tokens for a specific duration in blocks
     * @dev a check occurs to see if a user has previously deposited. If yes, then their current deposit amount
     * is added onto their previous deposit amount, and re-staked. For the previous deposit amount, the claims
     * are calculated, and stored in accruedRewards parameter in UserDepositInfo struct.
     * @param amount the amount of product tokens to deposit
     * @param duration the duration in blocks of the staking
     */
    function deposit(uint256 amount, uint256 duration) external;

    /**
     * @notice function for a user to claim rewards and their initial staked tokens
     */
    function claim() external;

    /**
     * @notice function to return the maxStakingDuration of a StakingPool
     */
    function getMaxStakingDuration() external view returns (uint256);

    /**
     * @notice function to return the maxEmissionSlots of a StakingPool
     */
    function getMaxEmissionSlots() external view returns (uint256);

    /**
     * @notice function to return the deploymentBlock of a StakingPool
     */
    function getDeploymentBlock() external view returns (uint256);

    /**
     * @notice function to return the emissionSlots of a StakingPool
     */
    function getEmissionSlots() external view returns (uint256);

    /**
     * @notice function to return the emissionRate of a StakingPool
     */
    function getEmissionRate() external view returns (uint256);
}

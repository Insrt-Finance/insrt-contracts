// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Insert Finance Staking Pool Interface
 * @author Insert Finance
 */
interface IStakingPool {
    /**
     * @notice lock a quantity of Insert Finance product tokens for a specified duration
     * @dev a check occurs to see if a user has previously deposited. If yes, then their current deposit amount
     * is added onto their previous deposit amount, and re-staked. For the previous deposit amount, the claims
     * are calculated, and stored in accruedRewards parameter in UserDepositInfo struct.
     * @param amount the amount of product tokens to deposit
     * @param duration the duration in seconds of the staking
     */
    function deposit(uint256 amount, uint256 duration) external;

    /**
     * @notice claim the total INSRT token rewards owed for the staking of Insert Finance product tokens
     */
    function claim() external;

    /**
     * @notice return the maxStakingDuration of a StakingPool
     */
    function getMaxStakingDuration() external view returns (uint256);

    /**
     * @notice return the maxEmissionSlots of a StakingPool
     */
    function getMaxEmissionSlots() external view returns (uint256);

    /**
     * @notice return the deploymentStamp of a StakingPool
     */
    function getDeploymentStamp() external view returns (uint256);

    /**
     * @notice return the emissionSlots of a StakingPool
     */
    function getEmissionSlots() external view returns (uint256);

    /**
     * @notice return the emissionRate of a StakingPool
     */
    function getEmissionRate() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

/**
 * @title Insrt Finance Staking Pool Interface
 * @author Insrt Finance
 */
interface IStakingPool {
    /**
     * @notice lock a quantity of Insrt Finance product tokens for a specified duration
     * @dev a check occurs to see if a user has previously deposited. If yes, then their current deposit amount
     * is added onto their previous deposit amount, and re-staked. For the previous deposit amount, the claims
     * are calculated, and stored in accruedRewards parameter in UserDepositInfo struct.
     * @param amount the amount of product tokens to deposit
     * @param duration the duration in seconds of the staking
     */
    function deposit(uint256 amount, uint256 duration) external;

    /**
     * @notice claim the total INSRT token rewards owed for the staking of Insrt Finance product tokens
     */
    function claim() external;

    /**
     * @notice return the maxStakingDuration of a StakingPool
     * @dev This is the life-time of the staking pool
     */
    function getMaxStakingDuration() external view returns (uint256);

    /**
     * @notice return the maxEmissionSlots of a StakingPool
     * @dev the maxEmissionSlots are the maximum tokens a StakingPool will accept for staking.
     * This is set by the StakingPoolFund in order to govern how many product tokens a single pool may
     * receive for staking.
     */
    function getMaxEmissionSlots() external view returns (uint256);

    /**
     * @notice return the deploymentStamp of a StakingPool
     */
    function getDeploymentStamp() external view returns (uint256);

    /**
     * @notice return the emissionSlots of a StakingPool
     * @dev emissionSlots are the amount of tokens which are currently staked
     */
    function getEmissionSlots() external view returns (uint256);

    /**
     * @notice return the emissionRate of a StakingPool
     * @dev the units are INSRT per Second
     */
    function getEmissionRate() external view returns (uint256);
}

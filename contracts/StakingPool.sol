// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { IStakingPool } from './IStakingPool.sol';
import { StakingPoolStorage } from './StakingPoolStorage.sol';

contract StakingPool is IStakingPool {
    using StakingPoolStorage for StakingPoolStorage.Layout;

    constructor(
        IERC20 insertToken,
        IERC20 productToken,
        uint256 maxEmissionSlots,
        uint256 emissionSlots,
        uint256 emissionRate,
        uint256 maxStakingDuration,
        uint256 totalEmissions
    ) {
        StakingPoolStorage.Layout storage l = StakingPoolStorage.layout();

        l.insertToken = insertToken;
        l.productToken = productToken;
        l.deploymentBlock = block.number;
        l.maxEmissionSlots = maxEmissionSlots;
        l.emissionSlots = emissionSlots;
        l.emissionRate = emissionRate;
        l.maxStakingDuration = maxStakingDuration;

        //WIP: Needs rework
        insertToken.transferFrom(msg.sender, address(this), totalEmissions);
    }

    /**
     * @inheritdoc IStakingPool
     */
    function deposit(uint256 amount, uint256 duration) external {
        StakingPoolStorage.Layout storage l = StakingPoolStorage.layout();

        require(
            l.emissionSlots + amount < l.maxEmissionSlots,
            'StakingPool: exceeded maxEmissionSlots'
        );
        require(
            l.deploymentBlock + l.maxStakingDuration - block.number > 0,
            'StakingPool: staking period complete'
        );
        require(
            duration < l.deploymentBlock + l.maxStakingDuration - block.number,
            'StakingPool: staking duration exceeds staking period'
        );

        if (l.userDepositInfo[msg.sender].previousDepositBlock != 0) {
            uint256 claims = _calculateClaims(
                l.userDepositInfo[msg.sender].amount,
                block.number -
                    l.userDepositInfo[msg.sender].previousDepositBlock,
                l.emissionRate,
                l.maxEmissionSlots
            );
            l.userDepositInfo[msg.sender].accruedRewards = claims;
        }

        l.productToken.transferFrom(msg.sender, address(this), amount);
        l.userDepositInfo[msg.sender].previousDepositBlock = block.number;
        l.userDepositInfo[msg.sender].duration = duration;
        l.userDepositInfo[msg.sender].amount += amount;
        l.emissionSlots += amount;
    }

    /**
     * @inheritdoc IStakingPool
     */
    function claim() external {
        StakingPoolStorage.Layout storage l = StakingPoolStorage.layout();

        require(
            l.userDepositInfo[msg.sender].duration + l.deploymentBlock >
                block.number,
            'StakingPool: user staking period has not elapsed'
        );

        uint256 outstandingClaims = (l.userDepositInfo[msg.sender].amount *
            l.userDepositInfo[msg.sender].duration *
            l.emissionRate) / l.maxEmissionSlots;

        uint256 totalClaims = outstandingClaims +
            l.userDepositInfo[msg.sender].accruedRewards;

        l.insertToken.transferFrom(address(this), msg.sender, totalClaims);
        l.productToken.transferFrom(
            address(this),
            msg.sender,
            l.userDepositInfo[msg.sender].amount
        );
    }

    /**
     * @inheritdoc IStakingPool
     */
    function getMaxStakingDuration() external view returns (uint256) {
        return StakingPoolStorage.layout().maxStakingDuration;
    }

    /**
     * @inheritdoc IStakingPool
     */
    function getMaxEmissionSlots() external view returns (uint256) {
        return StakingPoolStorage.layout().maxEmissionSlots;
    }

    /**
     * @inheritdoc IStakingPool
     */
    function getDeploymentBlock() external view returns (uint256) {
        return StakingPoolStorage.layout().deploymentBlock;
    }

    /**
     * @inheritdoc IStakingPool
     */
    function getEmissionSlots() external view returns (uint256) {
        return StakingPoolStorage.layout().emissionSlots;
    }

    /**
     * @inheritdoc IStakingPool
     */
    function getEmissionRate() external view returns (uint256) {
        return StakingPoolStorage.layout().emissionRate;
    }

    function _calculateClaims(
        uint256 amount,
        uint256 duration,
        uint256 emissionRate,
        uint256 maxEmissionSlots
    ) internal pure returns (uint256) {
        return (amount * duration * emissionRate) / maxEmissionSlots;
    }
}

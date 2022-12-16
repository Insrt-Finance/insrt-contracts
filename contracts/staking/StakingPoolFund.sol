// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { SafeOwnable } from '@solidstate/contracts/access/ownable/SafeOwnable.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { StakingPoolProxy } from './StakingPoolProxy.sol';
import { IStakingPool } from './IStakingPool.sol';
import { StakingPoolFundStorage } from './StakingPoolFundStorage.sol';

/**
 * @title Insrt Finance Staking Pool Fund contract
 * @author Insrt Finance
 * @notice StakingPool contracts deploying and managing
 */
contract StakingPoolFund is SafeOwnable {
    using StakingPoolFundStorage for StakingPoolFundStorage.Layout;

    constructor() {
        _setOwner(msg.sender);
    }

    function deployStakingPoolProxy(
        address underlying,
        uint256 maxEmissionSlots,
        uint256 emissionRate,
        uint256 maxStakingDuration,
        uint256 totalEmissions,
        address stakingImplementation
    ) external onlyOwner returns (address deployment) {
        StakingPoolFundStorage.Layout storage l = StakingPoolFundStorage
            .layout();

        address currentPool = l.getStakingPool(underlying);

        if (currentPool != address(0)) {
            require(
                IStakingPool(currentPool).getMaxStakingDuration() +
                    IStakingPool(currentPool).getDeploymentStamp() >
                    block.timestamp,
                'StakingPool: pool already exists and has not run out'
            );
        }

        deployment = address(
            new StakingPoolProxy(
                underlying,
                maxEmissionSlots,
                emissionRate,
                maxStakingDuration,
                totalEmissions,
                stakingImplementation
            )
        );

        l.setStakingPool(underlying, deployment);
    }
}

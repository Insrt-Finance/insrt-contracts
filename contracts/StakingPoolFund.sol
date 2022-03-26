// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { SafeOwnable } from '@solidstate/contracts/access/SafeOwnable.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { OwnableStorage } from '@solidstate/contracts/access/Ownable.sol';
import { StakingProxy } from './StakingProxy.sol';
import { IStakingPool } from './IStakingPool.sol';
import { StakingPoolFundStorage } from './StakingPoolFundStorage.sol';

/**
 * @title Insert Finance Staking Pool Fund contract
 * @author Insert Finance
 * @notice StakingPool contracts deploying and managing
 */
contract StakingPoolFund is SafeOwnable {
    using OwnableStorage for OwnableStorage.Layout;
    using StakingPoolFundStorage for StakingPoolFundStorage.Layout;

    constructor() {
        OwnableStorage.layout().setOwner(msg.sender);
    }

    function deployStakingPoolProxy(
        address insertToken,
        address productToken,
        uint256 maxEmissionSlots,
        uint256 emissionSlots,
        uint256 emissionRate,
        uint256 maxStakingDuration,
        uint256 totalEmissions,
        address stakingImplementation
    ) external onlyOwner returns (address) {
        StakingPoolFundStorage.Layout storage l = StakingPoolFundStorage
            .layout();
        address currentPool = l.getStakingPool(address(productToken));

        if (currentPool != address(0)) {
            require(
                IStakingPool(currentPool).getMaxStakingDuration() +
                    IStakingPool(currentPool).getDeploymentStamp() >
                    block.timestamp,
                'StakingPool: pool already exists and has not run out'
            );
        }

        address poolProxy = address(
            new StakingProxy(
                insertToken,
                productToken,
                maxEmissionSlots,
                emissionSlots,
                emissionRate,
                maxStakingDuration,
                totalEmissions,
                stakingImplementation
            )
        );

        StakingPoolFundStorage.layout().setStakingPool(
            address(productToken),
            poolProxy
        );

        return poolProxy;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { StakingPoolStorage } from './StakingPoolStorage.sol';

/**
 * @title Insrt Finance Staking Pool Proxy
 * @author Insrt Finance
 * @notice Proxy for StakingPool implementation
 */
contract StakingPoolProxy is Proxy {
    using StakingPoolStorage for StakingPoolStorage.Layout;

    address private immutable STAKING_IMPLEMENTATION;

    constructor(
        address productToken,
        uint256 maxEmissionSlots,
        uint256 emissionRate,
        uint256 maxStakingDuration,
        uint256 totalEmissions,
        address stakingImplementation
    ) {
        StakingPoolStorage.Layout storage l = StakingPoolStorage.layout();

        l.productToken = productToken;
        l.deploymentStamp = block.timestamp;
        l.maxEmissionSlots = maxEmissionSlots;
        l.emissionRate = emissionRate;
        l.maxStakingDuration = maxStakingDuration;

        STAKING_IMPLEMENTATION = stakingImplementation;

        //WIP: Needs rework
        // IERC20(insrtToken).transferFrom(
        //     msg.sender,
        //     address(this),
        //     totalEmissions
        // );
    }

    function _getImplementation() internal view override returns (address) {
        return STAKING_IMPLEMENTATION;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Proxy } from '@solidstate/contracts/proxy/Proxy.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { StakingPoolStorage } from './lib/StakingPoolStorage.sol';

contract StakingProxy is Proxy {
    using StakingPoolStorage for StakingPoolStorage.Layout;

    address private immutable STAKINGIMPLEMENTATION;

    constructor(
        IERC20 insertToken,
        IERC20 productToken,
        uint256 maxEmissionSlots,
        uint256 emissionSlots,
        uint256 emissionRate,
        uint256 maxStakingDuration,
        uint256 totalEmissions,
        address stakingImplementation
    ) {
        StakingPoolStorage.Layout storage l = StakingPoolStorage.layout();

        l.insertToken = insertToken;
        l.productToken = productToken;
        l.deploymentBlock = block.number;
        l.maxEmissionSlots = maxEmissionSlots;
        l.emissionSlots = emissionSlots;
        l.emissionRate = emissionRate;
        l.maxStakingDuration = maxStakingDuration;

        STAKINGIMPLEMENTATION = stakingImplementation;

        //WIP: Needs rework
        insertToken.transferFrom(msg.sender, address(this), totalEmissions);
    }

    function _getImplementation() internal view override returns (address) {
        return STAKINGIMPLEMENTATION;
    }
}

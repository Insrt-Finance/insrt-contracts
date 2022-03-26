// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

/**
 * @title Insert Finance Staking Pool Storage library
 * @author Insert Finance
 * @notice Storage layout of StakingPool contract
 */
library StakingPoolStorage {
    /**
     * @notice a struct to contain information pertaining to user deposits
     * @param duration the duration in seconds of the staking period for the deposit
     * @param amount the amount of LP tokens staked in total
     * @param previousDepositStamp the block timestamp in which the last deposit of the user occurred
     * @param accruedRewards the total rewards accrued by the user for each consecutive deposit
     */
    struct UserDepositInfo {
        uint256 duration;
        uint256 amount;
        uint256 previousDepositStamp;
        uint256 accruedRewards;
    }

    /**
     * @notice Layout struct for a staking pool
     * @param insertToken the token address of insert protocol
     * @param productToken the LP token address from an index
     * @param deploymentStamp the block timestamp which the staking pool was deployed in
     * @param maxEmissionSlots the maximum amount of product tokens accepted by the staking pool
     * @param emissionSlots the current amount of product tokens in the staking pool
     * @param emissionRate the amount of insert tokens emitted per second
     * @param maxStakingDuration the maximum duration a user can stake in the staking pool - the life-time of the staking pool
     * @param userDepositInfo a mapping from a user address to UserDepositInfo
     */

    struct Layout {
        address insertToken;
        address productToken;
        uint256 deploymentStamp;
        uint256 maxEmissionSlots;
        uint256 emissionSlots;
        uint256 emissionRate;
        uint256 maxStakingDuration;
        mapping(address => UserDepositInfo) userDepositInfo;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insert.contracts.storage.StakingPool');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

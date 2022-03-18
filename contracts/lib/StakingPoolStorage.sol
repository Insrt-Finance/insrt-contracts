// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

library StakingPoolStorage {
    struct UserDepositInfo {
        uint256 duration;
        uint256 amount;
        uint256 previousDepositBlock;
        uint256 accruedRewards;
    }

    struct Layout {
        IERC20 insertToken;
        IERC20 productToken;
        uint256 deploymentBlock;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

/**
 * @title Insert Finance Staking Pool Fund Storage library
 * @author Insert Finance
 * @notice Storage layout of StakingPoolFund contract
 */
library StakingPoolFundStorage {
    struct Layout {
        mapping(address => address) productTokenToPool;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insert.contracts.storage.StakingPoolFund');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setStakingPool(
        Layout storage l,
        address productToken,
        address pool
    ) external {
        l.productTokenToPool[productToken] = pool;
    }

    function getStakingPool(Layout storage l, address productToken)
        external
        view
        returns (address)
    {
        return l.productTokenToPool[productToken];
    }
}

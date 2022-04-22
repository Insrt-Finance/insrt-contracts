// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

library IndexStorage {
    struct Layout {
        address balancerPool;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insert.contracts.storage.Index');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

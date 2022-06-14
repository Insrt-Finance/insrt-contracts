// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

/**
 * @title IndexManagerStorage library
 */
library IndexManagerStorage {
    struct Layout {
        uint256 count;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insrt.contracts.storage.IndexManager');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

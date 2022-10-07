// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';

library ShardVaultStorage {
    struct Layout {
        uint256 id;
        uint256 shardSize;
        uint256 maxCapital;
        uint256 totalShards;
        address collection;
        bool capped;
        bool invested;
        bool divested;
        mapping(address => uint256) owedShards;
        EnumerableSet.AddressSet depositors;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('insrt.contracts.storage.ShardVault');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

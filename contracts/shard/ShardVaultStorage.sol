// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';

library ShardVaultStorage {
    struct Layout {
        uint256 id;
        uint256 count;
        uint256 shardValue;
        uint256 maxShards;
        uint256 mintedShards;
        address collection;
        bool vaultFull;
        bool invested;
        bool divested;
        mapping(address => uint256) depositorShards;
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

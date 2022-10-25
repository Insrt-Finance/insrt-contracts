// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';

library ShardVaultStorage {
    struct Layout {
        uint256 id;
        uint256 count;
        uint256 shardValue;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 lpFarmId;
        uint256 salesFeeBP;
        uint256 fundraiseFeeBP;
        uint256 yieldFeeBP;
        uint256 accruedFees;
        uint256 bufferBP;
        uint256 deviationBP;
        address treasury;
        address jpegdVault;
        address jpegdLP;
        address collection;
        bool invested;
        bool divested;
        EnumerableSet.UintSet ownedTokenIds;
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

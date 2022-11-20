// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';

library ShardVaultStorage {
    struct Layout {
        uint256 shardValue;
        uint256 accruedFees;
        uint64 whitelistEndsAt;
        uint16 whitelistShards;
        uint16 maxShardsPerUser;
        uint16 count;
        uint16 maxSupply;
        uint16 totalSupply;
        uint16 saleFeeBP;
        uint16 acquisitionFeeBP;
        uint16 yieldFeeBP;
        uint16 bufferBP;
        uint16 deviationBP;
        address treasury;
        address jpegdVault;
        address jpegdVaultHelper;
        address jpegdLP;
        address collection;
        bool isInvested;
        bool divested;
        bool isEnabled;
        EnumerableSet.UintSet ownedTokenIds;
        mapping(address => uint16) userShards;
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

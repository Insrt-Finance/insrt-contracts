// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';

library ShardVaultStorage {
    struct Layout {
        uint256 shardValue;
        uint256 accruedFees;
        uint256 conversionBuffer;
        uint256 cumulativeEPS; //EPS = ETH per shard
        uint64 whitelistEndsAt;
        uint16 reservedShards;
        uint16 maxUserShards;
        uint16 count;
        uint16 maxSupply;
        uint16 totalSupply;
        uint16 saleFeeBP;
        uint16 acquisitionFeeBP;
        uint16 yieldFeeBP;
        uint16 ltvBufferBP;
        uint16 ltvDeviationBP;
        address treasury;
        address jpegdVault;
        address jpegdVaultHelper;
        address jpegdLP;
        address collection;
        bool isInvested;
        bool isDivested;
        bool isEnabled;
        bool claimableETHProvided;
        EnumerableSet.UintSet ownedTokenIds;
        mapping(address => uint16) shardBalances;
        mapping(uint256 => uint256) claimedEPS; //EPS = ETH per shard
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

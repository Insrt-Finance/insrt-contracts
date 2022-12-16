// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';

library ShardVaultStorage {
    struct Layout {
        uint256 conversionBuffer; //temporary for ClosePunkPosition merge
        uint256 count;
        uint256 maxSupply;
        uint256 maxUserShards;
        uint256 reservedShards;
        uint256 shardValue;
        uint256 accruedFees;
        uint256 accruedJPEG;
        uint256 cumulativeETHPerShard;
        uint256 cumulativeJPEGPerShard;
        mapping(uint256 => uint256) claimedETHPerShard;
        mapping(uint256 => uint256) claimedJPEGPerShard;
        address collection;
        uint48 whitelistEndsAt;
        uint16 saleFeeBP;
        uint16 acquisitionFeeBP;
        uint16 yieldFeeBP;
        uint16 ltvBufferBP;
        uint16 ltvDeviationBP;
        bool isInvested;
        bool isEnabled;
        bool isPUSDVault;
        bool isYieldClaiming;
        address jpegdVault;
        address jpegdVaultHelper;
        address jpegdLP;
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

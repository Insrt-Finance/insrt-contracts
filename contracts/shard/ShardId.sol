// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Functionality for parsing & formating ShardIds
 */
library ShardId {
    /**
     * @notice formats a shardId given the internalId and address of ShardVault contract
     * @param vault address of vault to use as seed for ShardId
     * @param internalId the internal ID
     * @return shardId the formatted shardId
     */
    function formatShardId(
        address vault,
        uint96 internalId
    ) internal pure returns (uint256 shardId) {
        shardId = ((uint256(uint160(vault)) << 96) | internalId);
    }

    /**
     * @notice parses a shardId to extract seeded vault address and internalId
     * @param shardId shardId to parse
     * @return vault seeded vault address
     * @return internalId internal ID
     */
    function parseShardId(
        uint256 shardId
    ) internal pure returns (address vault, uint96 internalId) {
        vault = address(uint160(shardId >> 96));
        internalId = uint96(shardId & 0xFFFFFFFFFFFFFFFFFFFFFFFF);
    }
}

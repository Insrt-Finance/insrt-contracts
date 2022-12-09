// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Functionality for parsing & formating ShardIds
 */
library ShardId {
    /**
     * @notice formats a tokenId given the internalId and address of ShardVault contract
     * @param internalId the internal ID
     * @return tokenId the formatted tokenId
     */
    function formatTokenId(
        uint96 internalId
    ) internal view returns (uint256 tokenId) {
        tokenId = ((uint256(uint160(address(this))) << 96) | internalId);
    }

    /**
     * @notice parses a tokenId to extract seeded vault address and internalId
     * @param tokenId tokenId to parse
     * @return vault seeded vault address
     * @return internalId internal ID
     */
    function parseTokenId(
        uint256 tokenId
    ) internal pure returns (address vault, uint96 internalId) {
        vault = address(uint160(tokenId >> 96));
        internalId = uint96(tokenId & 0xFFFFFFFFFFFFFFFFFFFFFFFF);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IShardCollectionInternal {
    /**
     * @notice thrown when function called by non-shard vault
     */
    error ShardCollection__OnlyVault();

    /**
     * @notice thrown when function called by non-protocol owner
     */
    error ShardCollection__OnlyProtocolOwner();

    /**
     * @notice emitted when a vault is added to the whitelist
     * @param vault vault address
     */
    event WhitelistAddition(address vault);

    /**
     * @notice emitted when a vault is removed from the whitelist
     * @param vault vault address
     */
    event WhitelistRemoval(address vault);
}

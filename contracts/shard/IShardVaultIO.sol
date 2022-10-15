// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title ShardVault Input Output Interface
 */
interface IShardVaultIO {
    /**
     * @notice deposit ETH
     */
    function deposit() external payable;

    /**
     * @notice withdraw ETH for shards
     * @dev burns shards with ids in tokenIds array
     */
    function withdraw(uint256[] memory tokenIds) external payable;
}

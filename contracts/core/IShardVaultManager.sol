// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IShardVaultProxy } from '../shard/IShardVaultProxy.sol';

/**
 * @title ShardVault Manager contract interface
 */
interface IShardVaultManager {
    /**
     * @notice event logged upon ShardVaultProxy deployment
     * @param deployment address of ShardVaultProxy
     */
    event ShardVaultDeployed(address deployment);

    /**
     * @notice returns address of ShardVault Diamond contract
     * @return address of ShardVaultDiamond
     */
    function SHARD_VAULT_DIAMOND() external view returns (address);

    /**
     * @notice returns address of MarketPlaceHelper implementation contract
     * @return address of MarketPlaceHelper implementation
     */
    function MARKETPLACE_HELPER() external view returns (address);

    /**
     * @notice deploys a ShardVaultProxy
     * @param addresses addresses required to deploy a shard vault; see IShardVaultProxy
     * @param uints uints required to deploy a shard vault; see IShardVaultProxy
     * @param isPUSDVault indicates whether vault should be allowed to call PETH or PUSD functions
     */
    function deployShardVault(
        IShardVaultProxy.ShardVaultAddresses memory addresses,
        IShardVaultProxy.ShardVaultUints memory uints,
        bool isPUSDVault
    ) external returns (address deployment);
}

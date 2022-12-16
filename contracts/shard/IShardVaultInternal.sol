// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IOwnableInternal } from '@solidstate/contracts/access/ownable/IOwnableInternal.sol';

interface IShardVaultInternal is IOwnableInternal {
    struct JPEGParams {
        address PUSD;
        address PETH;
        address JPEG;
        address JPEG_CARDS_CIG_STAKING;
        address PUSD_CITADEL;
        address PETH_CITADEL;
        address CURVE_PUSD_POOL;
        address CURVE_PETH_POOL;
        address LP_FARM;
    }

    struct AuxiliaryParams {
        address PUNKS;
        address DAWN_OF_INSRT;
        address MARKETPLACE_HELPER;
        address TREASURY;
    }

    /**
     * @notice thrown when the deposit amount is not a multiple of shardSize
     */
    error ShardVault__InvalidDepositAmount();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error ShardVault__DepositForbidden();

    /**
     * @notice thrown when the withdraw amount exceeds the owed shards to the sender
     */
    error ShardVault__InsufficientShards();

    /**
     * @notice thrown when the maximum capital has been reached or vault has invested
     */
    error ShardVault__WithdrawalForbidden();

    /**
     * @notice thrown when attempt to purchase a punk is made when collection is not punks
     */
    error ShardVault__CollectionNotPunks();

    /**
     * @notice thrown when attempting to act on an unowned asset
     */
    error ShardVault__NotOwned();

    /**
     * @notice thrown when setting a basis point fee value larger than 10000
     */
    error ShardVault__BasisExceeded();

    /**
     * @notice thrown when function called by non-protocol owner
     */
    error ShardVault__NotProtocolOwner();

    /**
     * @notice thrown when function called by non-shard owner
     */
    error ShardVault__NotShardOwner();

    /**
     * @notice thrown when a shardId does not exist
     */
    error ShardVault__NonExistentShard();

    /**
     * @notice thrown when attempting to borrow after target LTV amount is reached
     */
    error ShardVault__TargetLTVReached();

    /**
     * @notice thrown when attempting to act without being whitelisted
     */
    error ShardVault__NotWhitelisted();

    /**
     * @notice thrown when attempting to call a disabled function
     */
    error ShardVault__NotEnabled();

    /**
     * @notice thrown when attempting to set whitelist deadline without setting reserved shards
     */
    error ShardVault__NoReservedShards();

    /**
     * @notice thrown when user is attempting to deposit when already owning max shards
     */
    error ShardVault__MaxUserShards();

    /**
     * @notice thrown when caller is not shard collection
     */
    error ShardVault__NotShardCollection();

    /**
     * @notice thrown when the actual downpayment amount is too small
     */
    error ShardVault__DownPaymentInsufficient();

    /**
     * @notice thrown when the vault is meant to handle PUSD but is called a PETH function or vice versa
     */
    error ShardVault__CallTypeProhibited();

    /**
     * @notice thrown when attempting to claim yield before yield claiming is initialized
     */
    error ShardVault__YieldClaimingForbidden();

    /**
     * @notice thrown when attempting to claim excess ETH after yield claiming is initialized
     */
    error ShardVault__ClaimingExcessETHForbidden();

    /**
     * @notice thrown when attempting to withdraw fees with treasury address == address(0)
     */
    error ShardVault__TreasuryIsZeroAddress();
}

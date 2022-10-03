// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { ERC1155BaseInternal } from '@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol';
import { ERC1155MetadataStorage } from '@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol';

import { Errors } from './Errors.sol';
import { ICryptoPunkMarket } from '../cryptopunk/ICryptoPunkMarket.sol';
import { ILPFarming } from '../jpegd/ILPFarming.sol';
import { INFTVault } from '../jpegd/INFTVault.sol';
import { IVault } from '../jpegd/IVault.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Shard Vault internal functions
 * @dev inherited by all Shard Vault implementation contracts
 */
abstract contract ShardVaultInternal is ERC1155BaseInternal {
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal immutable PUNKS;
    address internal immutable AUTO_COMPOUNDER;
    address internal immutable LP_FARM;

    constructor(
        address punkMarket,
        address compounder,
        address lpFarm
    ) {
        PUNKS = punkMarket;
        AUTO_COMPOUNDER = compounder;
        LP_FARM = lpFarm;
    }

    /**
     * @notice deposits ETH in exchange for owed shards
     */
    function _deposit() internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 amount = msg.value;

        if (amount % l.shardSize != 0 || amount == 0) {
            revert Errors.InvalidDepositAmount();
        }
        if (address(this).balance + amount > l.maxCapital) {
            revert Errors.MaxCapitalExceeded();
        }

        uint256 shards = amount / l.shardSize;
        l.owedShards[msg.sender] += shards;
        l.totalShards += shards;
        l.depositors.add(msg.sender);
    }

    /**
     * @notice withdraws ETH for an amount of shards
     * @param shards the amount of shards to "burn" for ETH
     */
    function _withdraw(uint256 shards) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.invested) {
            revert Errors.WithdrawalPeriodElapsed();
        }
        if (l.owedShards[msg.sender] < shards) {
            revert Errors.InsufficientShards();
        }

        l.owedShards[msg.sender] -= shards;
        l.totalShards -= shards;

        if (l.owedShards[msg.sender] == 0) {
            l.depositors.remove(msg.sender);
        }

        payable(msg.sender).sendValue(shards * l.shardSize);
    }

    function _purchasePunk(ShardVaultStorage.Layout storage l, uint256 punkId)
        internal
    {
        if (l.collection != PUNKS) {
            revert Errors.CollectionNotPunks();
        }

        uint256 price = ICryptoPunkMarket(PUNKS)
            .punksOfferedForSale(punkId)
            .minValue;

        ICryptoPunkMarket(PUNKS).buyPunk{ value: price }(punkId);

        l.invested = true;
    }

    function _collateralizePunk(
        ShardVaultStorage.Layout storage l,
        uint256 punkId,
        bool insure
    ) internal {
        if (
            ICryptoPunkMarket(PUNKS).punkIndexToAddress(punkId) != address(this)
        ) {
            revert Errors.NotOwned();
        }

        INFTVault(l.jpegdVault).borrow(
            punkId,
            INFTVault(l.jpegdVault).getNFTValueUSD(punkId),
            insure
        );
    }

    function _stake(ShardVaultStorage.Layout storage l, uint256 amount)
        internal
        returns (uint256 shares)
    {
        shares = IVault(AUTO_COMPOUNDER).deposit(address(this), amount);

        ILPFarming(LP_FARM).deposit(l.citadelId, shares);
    }
}

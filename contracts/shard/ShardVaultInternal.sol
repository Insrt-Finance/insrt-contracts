// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { ERC1155BaseInternal } from '@solidstate/contracts/token/ERC1155/base/ERC1155BaseInternal.sol';
import { ERC1155MetadataStorage } from '@solidstate/contracts/token/ERC1155/metadata/ERC1155MetadataStorage.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

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
    using EnumerableSet for EnumerableSet.UintSet;

    address internal immutable PUSD;
    address internal immutable PUNKS;
    address internal immutable AUTO_COMPOUNDER;
    address internal immutable LP_FARM;
    uint256 internal constant BASIS_POINTS = 10000;
    uint256 internal constant SALES_FEE_BP = 200;
    uint256 internal constant FUNDRAISING_FEE_BP = 100;
    uint256 internal constant YIELD_FEE = 1000;

    constructor(
        address pUSD,
        address punkMarket,
        address compounder,
        address lpFarm
    ) {
        PUNKS = punkMarket;
        AUTO_COMPOUNDER = compounder;
        LP_FARM = lpFarm;
        PUSD = pUSD;
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
        if (l.invested || l.capped) {
            revert Errors.DepositForbidden();
        }
        if (address(this).balance > l.maxCapital) {
            l.capped = true;
            amount = msg.value + l.maxCapital - address(this).balance;
        }

        uint256 shards = amount / l.shardSize;
        l.owedShards[msg.sender] += shards;
        l.totalShards += shards;
        l.depositors.add(msg.sender);

        if (msg.value - amount > 0) {
            payable(msg.sender).sendValue(msg.value - amount);
        }
    }

    /**
     * @notice withdraws ETH for an amount of shards
     * @param shards the amount of shards to "burn" for ETH
     */
    function _withdraw(uint256 shards) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.invested || l.capped) {
            revert Errors.WithdrawalForbidden();
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

    /**
     * @notice purchases a punk from CryptoPunkMarket
     * @param l ShardVaultStorage layout
     * @param punkId id of punk
     */
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

    /**
     * @notice borrows pUSD in exchange for collaterlizing a punk
     * @dev insuring is explained here: https://github.com/jpegd/core/blob/7581b11fc680ab7004ea869226ba21be01fc0a51/contracts/vaults/NFTVault.sol#L563
     * @param l ShardVaultStorage layout
     * @param punkId id of punk
     * @param insure whether to insure
     * @return pUSD the amount of pUSD received for the collateralized punk
     */
    function _collateralizePunk(
        ShardVaultStorage.Layout storage l,
        uint256 punkId,
        bool insure
    ) internal returns (uint256 pUSD) {
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

        pUSD = IERC20(PUSD).balanceOf(address(this));
    }

    /**
     * @notice stakes an amount of pUSD into JPEGd autocompounder and then into JPEGd citadel
     * @param l ShardVaultStorage layout
     * @param amount amount of pUSD to stake
     * @return shares deposited into JPEGd autocompounder
     */
    function _stake(ShardVaultStorage.Layout storage l, uint256 amount)
        internal
        returns (uint256 shares)
    {
        IERC20(PUSD).approve(AUTO_COMPOUNDER, amount);
        shares = IVault(AUTO_COMPOUNDER).deposit(address(this), amount);

        IERC20(ILPFarming(LP_FARM).poolInfo()[l.citadelId].lpToken).approve(
            LP_FARM,
            shares
        );
        ILPFarming(LP_FARM).deposit(l.citadelId, shares);
    }

    /**
     * @notice purchases and collateralizes a punk, and stakes all pUSD gained from collateralization
     * @param l ShardVaultStorage layout
     * @param punkId id of punk
     * @param insure whether to insure
     */
    function _investPunk(
        ShardVaultStorage.Layout storage l,
        uint256 punkId,
        bool insure
    ) internal {
        if (l.ownedTokenIds.length() == 0) {
            payable(l.treasury).sendValue(
                (address(this).balance * FUNDRAISING_FEE_BP) / BASIS_POINTS
            );
        }
        _purchasePunk(l, punkId);
        l.ownedTokenIds.add(punkId);
        _stake(l, _collateralizePunk(l, punkId, insure));
    }
}

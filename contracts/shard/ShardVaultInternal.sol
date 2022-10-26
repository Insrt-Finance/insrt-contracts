// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { ICryptoPunkMarket } from '../cryptopunk/ICryptoPunkMarket.sol';
import { ICurveMetaPool } from '../curve/ICurveMetaPool.sol';
import { ILPFarming } from '../jpegd/ILPFarming.sol';
import { INFTVault } from '../jpegd/INFTVault.sol';
import { IVault } from '../jpegd/IVault.sol';
import { IShardVaultInternal } from './IShardVaultInternal.sol';
import { IShardCollection } from './IShardCollection.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

/**
 * @title Shard Vault internal functions
 * @dev inherited by all Shard Vault implementation contracts
 */
abstract contract ShardVaultInternal is IShardVaultInternal, OwnableInternal {
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    address internal immutable SHARD_COLLECTION;
    address internal immutable PUSD;
    address internal immutable PUNKS;
    address internal immutable CITADEL;
    address internal immutable LP_FARM;
    address internal immutable CURVE_PUSD_POOL;
    uint256 internal constant BASIS_POINTS = 10000;

    constructor(
        address shardCollection,
        address pUSD,
        address punkMarket,
        address citadel,
        address lpFarm,
        address curvePUSDPool,
        uint256 salesFeeBP,
        uint256 fundraiseFeeBP,
        uint256 yieldFeeBP
    ) {
        SHARD_COLLECTION = shardCollection;
        PUNKS = punkMarket;
        PUSD = pUSD;
        CITADEL = citadel;
        LP_FARM = lpFarm;
        CURVE_PUSD_POOL = curvePUSDPool;

        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        l.salesFeeBP = salesFeeBP;
        l.fundraiseFeeBP = fundraiseFeeBP;
        l.yieldFeeBP = yieldFeeBP;
    }

    modifier onlyProtocolOwner() {
        _onlyProtocolOwner(msg.sender);
        _;
    }

    function _onlyProtocolOwner(address account) internal view {
        if (account != _protocolOwner()) {
            revert ShardVault__OnlyProtocolOwner();
        }
    }

    /**
     * @notice returns the protocol owner
     * @return address of the protocol owner
     */
    function _protocolOwner() internal view returns (address) {
        return IERC173(_owner()).owner();
    }

    /**
     * @notice deposits ETH in exchange for owed shards
     */
    function _deposit() internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 amount = msg.value;
        uint256 shardValue = l.shardValue;
        uint256 totalSupply = l.totalSupply;
        uint256 maxSupply = l.maxSupply;

        if (amount % shardValue != 0 || amount == 0) {
            revert ShardVault__InvalidDepositAmount();
        }
        if (l.invested || totalSupply == maxSupply) {
            revert ShardVault__DepositForbidden();
        }

        uint256 shards = amount / shardValue;
        uint256 excessShards;

        if (shards + totalSupply >= maxSupply) {
            excessShards = shards + totalSupply - maxSupply;
        }

        shards -= excessShards;
        l.totalSupply += shards;

        for (uint256 i; i < shards; ) {
            unchecked {
                IShardCollection(SHARD_COLLECTION).mint(
                    msg.sender,
                    _formatTokenId(++l.count)
                );
                ++i;
            }
        }

        if (excessShards > 0) {
            payable(msg.sender).sendValue(excessShards * shardValue);
        }
    }

    /**
     * @notice withdraws ETH for an amount of shards
     * @param tokenIds the tokenIds of shards to burn
     */
    function _withdraw(uint256[] memory tokenIds) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.invested || l.totalSupply == l.maxSupply) {
            revert ShardVault__WithdrawalForbidden();
        }

        uint256 tokens = tokenIds.length;

        if (IShardCollection(SHARD_COLLECTION).balanceOf(msg.sender) < tokens) {
            revert ShardVault__InsufficientShards();
        }

        for (uint256 i; i < tokens; ) {
            if (
                IShardCollection(SHARD_COLLECTION).ownerOf(tokenIds[i]) !=
                msg.sender
            ) {
                revert ShardVault__OnlyShardOwner();
            }

            (address vault, ) = _parseTokenId(tokenIds[i]);
            if (vault != address(this)) {
                revert ShardVault__VaultTokenIdMismatch();
            }

            IShardCollection(SHARD_COLLECTION).burn(tokenIds[i]);

            unchecked {
                ++i;
            }
        }

        l.totalSupply -= tokens;

        payable(msg.sender).sendValue(tokens * l.shardValue);
    }

    /**
     * @notice returns total minted shards amount
     */
    function _totalSupply() internal view returns (uint256) {
        return ShardVaultStorage.layout().totalSupply;
    }

    /**
     * @notice returns maximum possible minted shards
     */
    function _maxSupply() internal view returns (uint256) {
        return ShardVaultStorage.layout().maxSupply;
    }

    /**
     * @notice returns ETH value of shard
     */
    function _shardValue() internal view returns (uint256) {
        return ShardVaultStorage.layout().shardValue;
    }

    /**
     * @notice return ShardCollection address
     */
    function _shardCollection() internal view returns (address) {
        return SHARD_COLLECTION;
    }

    /**
     * @notice return minted token count
     * @dev does not reduce when tokens are burnt
     */
    function _count() internal view returns (uint256) {
        return ShardVaultStorage.layout().count;
    }

    /**
     * @notice return invested flag state
     * @return bool invested flag
     */
    function _invested() internal view returns (bool) {
        return ShardVaultStorage.layout().invested;
    }

    /**
     * @notice return array with owned token IDs
     * @return uint256[]  array of owned token IDs
     */
    function _ownedTokenIds() internal view returns (uint256[] memory) {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        uint256 ownedIdsLength = l.ownedTokenIds.length();
        uint256[] memory ids = new uint256[](ownedIdsLength);

        unchecked {
            for (uint256 i; i < ownedIdsLength; ) {
                ids[i] = l.ownedTokenIds.at(i);
                ++i;
            }
        }

        return ids;
    }

    /**
     * @notice formats a tokenId given the internalId and address of ShardVault contract
     * @param internalId the internal ID
     * @return tokenId the formatted tokenId
     */
    function _formatTokenId(uint256 internalId)
        internal
        view
        returns (uint256 tokenId)
    {
        tokenId = ((uint256(uint160(address(this))) << 96) | internalId);
    }

    /**
     * @notice parses a tokenId to extract seeded vault address and internalId
     * @param tokenId tokenId to parse
     * @return vault seeded vault address
     * @return internalId internal ID
     */
    function _parseTokenId(uint256 tokenId)
        internal
        pure
        returns (address vault, uint256 internalId)
    {
        vault = address(uint160(tokenId >> 96));
        internalId = 0xFFFFFFFFFFFFFFFFFFFFFFFF & tokenId;
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
            revert ShardVault__CollectionNotPunks();
        }

        uint256 price = ICryptoPunkMarket(PUNKS)
            .punksOfferedForSale(punkId)
            .minValue;

        ICryptoPunkMarket(PUNKS).buyPunk{ value: price }(punkId);

        l.invested = true;
        l.ownedTokenIds.add(punkId);
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
        uint256 borrowAmount,
        bool insure
    ) internal returns (uint256 pUSD) {
        uint256 creditLimit = INFTVault(l.jpegdVault).getCreditLimit(punkId);

        if (
            borrowAmount >
            creditLimit -
                ((creditLimit * (BASIS_POINTS - l.bufferBP - l.deviationBP)) /
                    BASIS_POINTS)
        ) {
            revert ShardVault__TargetLTVExceeded();
        }

        INFTVault(l.jpegdVault).borrow(punkId, borrowAmount, insure);

        pUSD = IERC20(PUSD).balanceOf(address(this));
    }

    /**
     * @notice stakes an amount of pUSD into JPEGd autocompounder and then into JPEGd citadel
     * @param l ShardVaultStorage layout
     * @param amount amount of pUSD to stake
     * @param minCurveLP minimum LP to receive from pUSD staking into curve
     * @return shares deposited into JPEGd autocompounder
     */
    function _stake(
        ShardVaultStorage.Layout storage l,
        uint256 amount,
        uint256 minCurveLP
    ) internal returns (uint256 shares) {
        IERC20(PUSD).approve(CURVE_PUSD_POOL, amount);
        //pUSD is in position 0 in the curve meta pool
        uint256 curveLP = ICurveMetaPool(CURVE_PUSD_POOL).add_liquidity(
            [amount, 0],
            minCurveLP
        );

        IERC20(CURVE_PUSD_POOL).approve(CITADEL, curveLP);
        shares = IVault(CITADEL).deposit(address(this), curveLP);

        IERC20(ILPFarming(LP_FARM).poolInfo()[l.lpFarmId].lpToken).approve(
            LP_FARM,
            shares
        );
        ILPFarming(LP_FARM).deposit(l.lpFarmId, shares);
    }

    /**
     * @notice purchases and collateralizes a punk, and stakes all pUSD gained from collateralization
     * @param l ShardVaultStorage layout
     * @param punkId id of punk
     * @param minCurveLP minimum LP to receive from curve LP
     * @param insure whether to insure
     */
    function _investPunk(
        ShardVaultStorage.Layout storage l,
        uint256 punkId,
        uint256 borrowAmount,
        uint256 minCurveLP,
        bool insure
    ) internal {
        if (l.ownedTokenIds.length() == 0) {
            _collectFee(l, l.fundraiseFeeBP);
        }
        _purchasePunk(l, punkId);
        _stake(
            l,
            _collateralizePunk(l, punkId, borrowAmount, insure),
            minCurveLP
        );
    }

    /**
     * @notice increment accrued fees
     * @param l storage layout
     * @param feeBP fee basis points
     */
    function _collectFee(ShardVaultStorage.Layout storage l, uint256 feeBP)
        internal
        view
    {
        uint256 accruedFees = l.accruedFees;
        accruedFees +=
            ((address(this).balance - accruedFees) * feeBP) /
            BASIS_POINTS;
    }

    /**
     * @notice sets the sales fee BP
     * @param feeBP basis points value of fee
     */
    function _setSalesFee(uint256 feeBP) internal {
        if (feeBP > 10000) revert ShardVault__BasisExceeded();
        ShardVaultStorage.layout().salesFeeBP = feeBP;
    }

    /**
     * @notice sets the fundraise fee BP
     * @param feeBP basis points value of fee
     */
    function _setFundraiseFee(uint256 feeBP) internal {
        if (feeBP > 10000) revert ShardVault__BasisExceeded();
        ShardVaultStorage.layout().fundraiseFeeBP = feeBP;
    }

    /**
     * @notice sets the Yield fee BP
     * @param feeBP basis points value of fee
     */
    function _setYieldFee(uint256 feeBP) internal {
        if (feeBP > 10000) revert ShardVault__BasisExceeded();
        ShardVaultStorage.layout().yieldFeeBP = feeBP;
    }

    /**
     * @notice sets the maxSupply of shards
     * @param maxSupply the maxSupply of shards
     */
    function _setMaxSupply(uint256 maxSupply) internal {
        ShardVaultStorage.layout().maxSupply = maxSupply;
    }
}

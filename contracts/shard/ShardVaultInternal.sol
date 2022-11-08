// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { ICryptoPunkMarket } from '../interfaces/cryptopunk/ICryptoPunkMarket.sol';
import { ICurveMetaPool } from '../interfaces/curve/ICurveMetaPool.sol';
import { ILPFarming } from '../interfaces/jpegd/ILPFarming.sol';
import { IMarketPlaceHelper } from '../helpers/IMarketPlaceHelper.sol';
import { INFTEscrow } from '../interfaces/jpegd/INFTEscrow.sol';
import { INFTVault } from '../interfaces/jpegd/INFTVault.sol';
import { IVault } from '../interfaces/jpegd/IVault.sol';
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
    address internal immutable PETH;
    address internal immutable PUNKS;
    address internal immutable PUSD_CITADEL;
    address internal immutable PETH_CITADEL;
    address internal immutable LP_FARM;
    address internal immutable CURVE_PUSD_POOL;
    address internal immutable CURVE_PETH_POOL;
    address internal immutable BOOSTER;
    address internal immutable MARKETPLACE_HELPER;
    uint256 internal constant BASIS_POINTS = 10000;

    constructor(
        address shardCollection,
        address pUSD,
        address pETH,
        address punkMarket,
        address pusdCitadel,
        address pethCitadel,
        address lpFarm,
        address curvePUSDPool,
        address curvePETHPool,
        address booster,
        address marketplaceHelper
    ) {
        SHARD_COLLECTION = shardCollection;
        PUNKS = punkMarket;
        PUSD = pUSD;
        PETH = pETH;
        PUSD_CITADEL = pusdCitadel;
        PETH_CITADEL = pethCitadel;
        LP_FARM = lpFarm;
        CURVE_PUSD_POOL = curvePUSDPool;
        CURVE_PETH_POOL = curvePETHPool;
        BOOSTER = booster;
        MARKETPLACE_HELPER = marketplaceHelper;
    }

    modifier onlyProtocolOwner() {
        _onlyProtocolOwner(msg.sender);
        _;
    }

    function _onlyProtocolOwner(address account) internal view {
        if (account != _protocolOwner()) {
            revert ShardVault__NotProtocolOwner();
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
        l.totalSupply += uint16(shards);

        for (uint256 i; i < shards; ) {
            unchecked {
                IShardCollection(SHARD_COLLECTION).mint(
                    msg.sender,
                    _formatTokenId(uint96(++l.count))
                );
                ++i;
            }
        }

        if (excessShards > 0) {
            payable(msg.sender).sendValue(excessShards * shardValue);
        }
    }

    /**
     * @notice burn held shards before NFT acquisition and withdraw corresponding ETH
     * @param tokenIds list of ids of shards to burn
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
                revert ShardVault__NotShardOwner();
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

        l.totalSupply -= uint16(tokens);

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

        for (uint256 i; i < ownedIdsLength; ) {
            unchecked {
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
    function _formatTokenId(uint96 internalId)
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
        returns (address vault, uint96 internalId)
    {
        vault = address(uint160(tokenId >> 96));
        internalId = uint96(tokenId & 0xFFFFFFFFFFFFFFFFFFFFFFFF);
    }

    /**
     * @notice purchases a punk from CryptoPunkMarket
     * @param punkId id of punk
     */
    function _purchasePunk(bytes calldata data, uint256 punkId) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.collection != PUNKS) {
            revert ShardVault__CollectionNotPunks();
        }

        uint256 price = ICryptoPunkMarket(PUNKS)
            .punksOfferedForSale(punkId)
            .minValue;

        IMarketPlaceHelper(MARKETPLACE_HELPER).purchaseERC721Asset{
            value: price
        }(data, PUNKS, PUNKS, address(0), punkId, price);

        l.invested = true;
        if (l.ownedTokenIds.length() == 0) {
            //first fee withdraw, so no account for previous
            //fee accruals need to be considered
            l.accruedFees += (price * l.acquisitionFeeBP) / BASIS_POINTS;
        }
        l.ownedTokenIds.add(punkId);
    }

    /**
     * @notice borrows pUSD in exchange for collaterlizing a punk
     * @dev insuring is explained here: https://github.com/jpegd/core/blob/7581b11fc680ab7004ea869226ba21be01fc0a51/contracts/vaults/NFTVault.sol#L563
     * @param punkId id of punk
     * @param insure whether to insure
     * @return pUSD the amount of pUSD received for the collateralized punk
     */
    function _collateralizePunkPUSD(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) internal returns (uint256 pUSD) {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        address jpegdVault = l.jpegdVault;
        uint256 creditLimit = INFTVault(jpegdVault).getCreditLimit(punkId);
        uint256 value = INFTVault(jpegdVault).getNFTValueUSD(punkId);
        uint256 targetLTV = creditLimit -
            (value * (l.bufferBP + l.deviationBP)) /
            BASIS_POINTS;

        if (INFTVault(jpegdVault).positionOwner(punkId) != address(0)) {
            uint256 principal = INFTVault(jpegdVault)
                .positions(punkId)
                .debtPrincipal;
            uint256 debtInterest = INFTVault(jpegdVault).getDebtInterest(
                punkId
            );

            if (borrowAmount + principal + debtInterest > targetLTV) {
                if (targetLTV < principal + debtInterest) {
                    revert ShardVault__TargetLTVReached();
                }
                borrowAmount = targetLTV - principal - debtInterest;
            }
        } else {
            if (borrowAmount > targetLTV) {
                borrowAmount = targetLTV;
            }

            (, address flashEscrow) = INFTEscrow(l.jpegdVaultHelper).precompute(
                address(this),
                punkId
            );
            ICryptoPunkMarket(PUNKS).transferPunk(flashEscrow, punkId);
        }

        INFTVault(jpegdVault).borrow(punkId, borrowAmount, insure);

        pUSD = IERC20(PUSD).balanceOf(address(this));
    }

    function _collateralizePunkPETH(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) internal returns (uint256 pETH) {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        address jpegdVault = l.jpegdVault;
        uint256 creditLimit = INFTVault(jpegdVault).getCreditLimit(punkId);
        uint256 value = INFTVault(jpegdVault).getNFTValueETH(punkId);
        uint256 targetLTV = creditLimit -
            (value * (l.bufferBP + l.deviationBP)) /
            BASIS_POINTS;

        if (INFTVault(jpegdVault).positionOwner(punkId) != address(0)) {
            uint256 principal = INFTVault(jpegdVault)
                .positions(punkId)
                .debtPrincipal;
            uint256 debtInterest = INFTVault(jpegdVault).getDebtInterest(
                punkId
            );

            if (borrowAmount + principal + debtInterest > targetLTV) {
                if (targetLTV < principal + debtInterest) {
                    revert ShardVault__TargetLTVReached();
                }
                borrowAmount = targetLTV - principal - debtInterest;
            }
        } else {
            if (borrowAmount > targetLTV) {
                borrowAmount = targetLTV;
            }

            (, address flashEscrow) = INFTEscrow(l.jpegdVaultHelper).precompute(
                address(this),
                punkId
            );
            ICryptoPunkMarket(PUNKS).transferPunk(flashEscrow, punkId);
        }

        INFTVault(jpegdVault).borrow(punkId, borrowAmount, insure);

        pETH = IERC20(PETH).balanceOf(address(this));
    }

    /**
     * @notice stakes an amount of pUSD into JPEGd autocompounder and then into JPEGd PUSD_CITADEL
     * @param amount amount of pUSD to stake
     * @param minCurveLP minimum LP to receive from pUSD staking into curve
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     *                      the pool to deposit into
     * @return shares deposited into JPEGd autocompounder
     */
    function _stakePUSD(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) internal returns (uint256 shares) {
        IERC20(PUSD).approve(CURVE_PUSD_POOL, amount);
        //pUSD is in position 0 in the curve meta pool
        uint256 curveLP = ICurveMetaPool(CURVE_PUSD_POOL).add_liquidity(
            [amount, 0],
            minCurveLP
        );

        IERC20(CURVE_PUSD_POOL).approve(PUSD_CITADEL, curveLP);
        shares = IVault(PUSD_CITADEL).deposit(address(this), curveLP);

        IERC20(ILPFarming(LP_FARM).poolInfo(poolInfoIndex).lpToken).approve(
            LP_FARM,
            shares
        );
        ILPFarming(LP_FARM).deposit(poolInfoIndex, shares);
    }

    /**
     * @notice stakes an amount of pETH into JPEGd autocompounder and then into JPEGd PETH_CITADEL
     * @param amount amount of pETH to stake
     * @param minCurveLP minimum LP to receive from pETH staking into curve
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     *                      the pool to deposit into
     * @return shares deposited into JPEGd autocompounder
     */
    function _stakePETH(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) internal returns (uint256 shares) {
        IERC20(PETH).approve(CURVE_PETH_POOL, amount);
        //pETH is in position 1 in the curve meta pool
        uint256 curveLP = ICurveMetaPool(CURVE_PETH_POOL).add_liquidity(
            [0, amount],
            minCurveLP
        );

        IERC20(CURVE_PETH_POOL).approve(PETH_CITADEL, curveLP);
        shares = IVault(PETH_CITADEL).deposit(address(this), curveLP);

        IERC20(ILPFarming(LP_FARM).poolInfo(poolInfoIndex).lpToken).approve(
            LP_FARM,
            shares
        );

        ILPFarming(LP_FARM).deposit(poolInfoIndex, shares);
    }

    /**
     * @notice purchases and collateralizes a punk, and stakes all pUSD gained from collateralization
     * @param punkId id of punk
     * @param minCurveLP minimum LP to receive from curve LP
     * @param insure whether to insure
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     *                      the pool to deposit into
     */
    function _investPunk(
        bytes calldata data,
        uint256 punkId,
        uint256 borrowAmount,
        uint256 minCurveLP,
        uint256 poolInfoIndex,
        bool insure
    ) internal {
        _purchasePunk(data, punkId);
        _stakePUSD(
            _collateralizePunkPUSD(punkId, borrowAmount, insure),
            minCurveLP,
            poolInfoIndex
        );
    }

    /**
     * @notice sets the sale fee BP
     * @param feeBP basis points value of fee
     */
    function _setSaleFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        ShardVaultStorage.layout().saleFeeBP = feeBP;
    }

    /**
     * @notice sets the acquisition fee BP
     * @param feeBP basis points value of fee
     */
    function _setAcquisitionFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        ShardVaultStorage.layout().acquisitionFeeBP = feeBP;
    }

    /**
     * @notice sets the Yield fee BP
     * @param feeBP basis points value of fee
     */
    function _setYieldFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        ShardVaultStorage.layout().yieldFeeBP = feeBP;
    }

    /**
     * @notice sets the maxSupply of shards
     * @param maxSupply the maxSupply of shards
     */
    function _setMaxSupply(uint16 maxSupply) internal {
        ShardVaultStorage.layout().maxSupply = maxSupply;
    }

    /**
     * @notice returns accrued fees
     * @return fees accrued fees
     */
    function _accruedFees() internal view returns (uint256 fees) {
        fees = ShardVaultStorage.layout().accruedFees;
    }

    /**
     * @notice returns acquisition fee BP
     * @return acquisitionFeeBP basis points of acquisition fee
     */
    function _acquisitionFeeBP()
        internal
        view
        returns (uint256 acquisitionFeeBP)
    {
        acquisitionFeeBP = ShardVaultStorage.layout().acquisitionFeeBP;
    }

    /**
     * @notice returns sale fee BP
     * @return saleFeeBP basis points of sale fee
     */
    function _saleFeeBP() internal view returns (uint256 saleFeeBP) {
        saleFeeBP = ShardVaultStorage.layout().saleFeeBP;
    }

    /**
     * @notice returns yield fee BP
     * @return yieldFeeBP basis points of yield fee
     */
    function _yieldFeeBP() internal view returns (uint256 yieldFeeBP) {
        yieldFeeBP = ShardVaultStorage.layout().yieldFeeBP;
    }

    /**
     * @notice enforces that a value cannot exceed BASIS_POINTS
     * @param value the value to check
     */
    function _enforceBasis(uint16 value) internal pure {
        if (value > 10000) revert ShardVault__BasisExceeded();
    }
}

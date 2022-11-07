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
import { IMarketPlaceHelper } from './IMarketPlaceHelper.sol';
import { INFTEscrow } from '../jpegd/INFTEscrow.sol';
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
    uint256 internal constant INTEREST_BUFFER = 5;

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
        l.totalSupply += shards;

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
     * @param l ShardVaultStorage layout
     * @param punkId id of punk
     */
    function _purchasePunk(
        ShardVaultStorage.Layout storage l,
        bytes calldata data,
        uint256 punkId
    ) internal {
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

    function _pethCollateralizePunk(
        ShardVaultStorage.Layout storage l,
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) internal returns (uint256 pETH) {
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
    function _stake(
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
    function _pethStake(
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
     * @param l ShardVaultStorage layout
     * @param punkId id of punk
     * @param minCurveLP minimum LP to receive from curve LP
     * @param insure whether to insure
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     *                      the pool to deposit into
     */
    function _investPunk(
        ShardVaultStorage.Layout storage l,
        bytes calldata data,
        uint256 punkId,
        uint256 borrowAmount,
        uint256 minCurveLP,
        uint256 poolInfoIndex,
        bool insure
    ) internal {
        _purchasePunk(l, data, punkId);
        _stake(
            _collateralizePunk(l, punkId, borrowAmount, insure),
            minCurveLP,
            poolInfoIndex
        );
    }

    /**
     * @notice sets the sale fee BP
     * @param feeBP basis points value of fee
     */
    function _setSaleFee(uint256 feeBP) internal {
        if (feeBP > 10000) revert ShardVault__BasisExceeded();
        ShardVaultStorage.layout().saleFeeBP = feeBP;
    }

    /**
     * @notice sets the acquisition fee BP
     * @param feeBP basis points value of fee
     */
    function _setAcquisitionFee(uint256 feeBP) internal {
        if (feeBP > 10000) revert ShardVault__BasisExceeded();
        ShardVaultStorage.layout().acquisitionFeeBP = feeBP;
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
     * @notice unstakes from JPEG'd LPFarming, then from JPEG'd citadel, then from curve LP
     * @param amount amount of shares of auto-compounder to burn
     * @param minPUSD minimum pUSD to receive from curve pool
     * @param poolInfoIndex the index of the JPEG'd LPFarming pool
     * @return pUSD pUSD amount returned
     */
    function _unstake(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex
    ) internal returns (uint256 pUSD) {
        ILPFarming(LP_FARM).withdraw(poolInfoIndex, amount);

        uint256 curveLP = IVault(PUSD_CITADEL).withdraw(
            address(this),
            IERC20(ILPFarming(LP_FARM).poolInfo(poolInfoIndex).lpToken)
                .balanceOf(address(this))
        );

        pUSD = ICurveMetaPool(CURVE_PUSD_POOL).remove_liquidity_one_coin(
            curveLP,
            0, //id of pUSD in curve pool
            minPUSD
        );
    }

    /**
     * @notice unstakes from JPEG'd LPFarming, then from JPEG'd citadel, then from curve LP
     * @param amount amount of shares of auto-compounder to burn
     * @param minPETH minimum pETH to receive from curve pool
     * @param poolInfoIndex the index of the JPEG'd LPFarming pool
     * @return pETH pETH amount returned
     */
    function _pethUnstake(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex
    ) internal returns (uint256 pETH) {
        ILPFarming(LP_FARM).withdraw(poolInfoIndex, amount);

        uint256 curveLP = IVault(PETH_CITADEL).withdraw(
            address(this),
            IERC20(ILPFarming(LP_FARM).poolInfo(poolInfoIndex).lpToken)
                .balanceOf(address(this))
        );

        pETH = ICurveMetaPool(CURVE_PETH_POOL).remove_liquidity_one_coin(
            curveLP,
            1, //id of pETH in curve pool
            minPETH
        );
    }

    /**
     * @notice liquidates all staked tokens in order to pay back loan, retrieves collateralized punk,
     *         and lists punk for sale
     * @param l storage layout
     * @param punkId id of punk position pertains to
     * @param minPUSD minimum pUSD to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param ask minimum accepted sale price of punk
     */
    function _closePunkPosition(
        ShardVaultStorage.Layout storage l,
        uint256 punkId,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 ask
    ) internal {
        address jpegdVault = l.jpegdVault;
        _unstake(
            ILPFarming(LP_FARM).userInfo(poolInfoIndex, address(this)).amount,
            minPUSD,
            poolInfoIndex
        );

        uint256 bufferedDebt = _totalDebtWithBuffer(jpegdVault, punkId);

        IERC20(PUSD).approve(jpegdVault, bufferedDebt);
        INFTVault(jpegdVault).repay(punkId, bufferedDebt + INTEREST_BUFFER);
        INFTVault(jpegdVault).closePosition(punkId);

        ICryptoPunkMarket(PUNKS).offerPunkForSale(punkId, ask);
    }

    /**
     * @notice makes a downpayment for a collateralized NFT in jpeg'd
     * @param l storage layout
     * @param amount amount of pUSD intended to be repaid
     * @param minPUSD minimum pUSD to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param punkId id of punk position pertains to
     * @return paidDebt amount of debt repaid
     */
    function _downPayment(
        ShardVaultStorage.Layout storage l,
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 punkId
    ) internal returns (uint256 paidDebt) {
        uint256 autoComp = _convertPUSDToAutoComp(amount);
        paidDebt = _unstake(autoComp, minPUSD, poolInfoIndex);

        if (amount > paidDebt) {
            revert ShardVault__DownPaymentInsufficient();
        }

        IERC20(PUSD).approve(l.jpegdVault, paidDebt);
        INFTVault(l.jpegdVault).repay(punkId, paidDebt);
    }

    /**
     * @notice converts an amount of AutoComp tokens to an amount of pUSD
     * @param autoComp amount of AutoComp tokens to convert
     * @return pUSD amount of pUSD returned
     */
    function _convertAutoCompToPUSD(
        uint256 autoComp // autocomp
    ) internal view returns (uint256 pUSD) {
        pUSD = ICurveMetaPool(CURVE_PUSD_POOL).calc_withdraw_one_coin(
            IVault(PUSD_CITADEL).exchangeRate() * autoComp,
            0
        );
    }

    /**
     * @notice calculates amount of AutoComp tokens needed for an amount of pUSD to be unstaked
     * @param pUSD target amount of pUSD
     * @return autoComp amount of AutoComp required for target
     */
    function _convertPUSDToAutoComp(uint256 pUSD)
        internal
        view
        returns (uint256 autoComp)
    {
        //note: does not account for fees, not meant for precise calculations.
        //      this is alright because it acts as a small 'buffer' to the amount
        //      necessary for the downpayment to impact the debt as intended
        uint256 curveLP = ICurveMetaPool(CURVE_PUSD_POOL).calc_token_amount(
            [pUSD, 0],
            true
        );

        IVault.Rate memory rate = IVault(PUSD_CITADEL).depositFeeRate();

        uint256 curveLPAccountingFee = curveLP +
            (curveLP * rate.numerator) /
            rate.denominator;

        autoComp =
            (curveLPAccountingFee * 10**IVault(PUSD_CITADEL).decimals()) /
            IVault(PUSD_CITADEL).exchangeRate();
    }

    /**
     * @notice withdraws any proceeds generated from punk sales
     * @param l storage layout
     * @param punkId the index of the punk proceeds were generated by
     */
    function _withdrawPunkProceeds(
        ShardVaultStorage.Layout storage l,
        uint256 punkId
    ) internal {
        ICryptoPunkMarket(PUNKS).withdraw();
        l.ownedTokenIds.remove(punkId);
    }

    /**
     * @notice returns total debt owed to jpeg'd vault for a given token
     * @param jpegdVault address of jpeg'd NFT vault
     * @param tokenId id of token position pertains to
     * @return debt total debt owed
     */
    function _totalDebt(address jpegdVault, uint256 tokenId)
        internal
        view
        returns (uint256 debt)
    {
        debt =
            INFTVault(jpegdVault).getDebtInterest(tokenId) +
            INFTVault(jpegdVault).positions(tokenId).debtPrincipal;
    }

    function _totalDebtWithBuffer(address jpegdVault, uint256 tokenId)
        internal
        view
        returns (uint256 bufferedDebt)
    {
        uint256 interest = INFTVault(jpegdVault).getDebtInterest(tokenId);
        bufferedDebt =
            INFTVault(jpegdVault).positions(tokenId).debtPrincipal +
            interest +
            (interest * INTEREST_BUFFER) /
            BASIS_POINTS;
    }

    /**
     * @notice sets the maxSupply of shards
     * @param maxSupply the maxSupply of shards
     */
    function _setMaxSupply(uint256 maxSupply) internal {
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
}

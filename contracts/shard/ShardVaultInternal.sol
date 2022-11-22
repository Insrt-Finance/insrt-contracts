// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IERC173 } from '@solidstate/contracts/interfaces/IERC173.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { IShardVaultInternal } from './IShardVaultInternal.sol';
import { IShardCollection } from './IShardCollection.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';
import { ICryptoPunkMarket } from '../interfaces/cryptopunk/ICryptoPunkMarket.sol';
import { ICurveMetaPool } from '../interfaces/curve/ICurveMetaPool.sol';
import { ILPFarming } from '../interfaces/jpegd/ILPFarming.sol';
import { INFTEscrow } from '../interfaces/jpegd/INFTEscrow.sol';
import { INFTVault } from '../interfaces/jpegd/INFTVault.sol';
import { IVault } from '../interfaces/jpegd/IVault.sol';
import { IMarketPlaceHelper } from '../helpers/IMarketPlaceHelper.sol';

import 'hardhat/console.sol';

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
    address internal immutable JPEG;
    address internal immutable PUNKS;
    address internal immutable PUSD_CITADEL;
    address internal immutable PETH_CITADEL;
    address internal immutable LP_FARM;
    address internal immutable CURVE_PUSD_POOL;
    address internal immutable CURVE_PETH_POOL;
    address internal immutable DAWN_OF_INSRT;
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
        address dawnOfInsrt,
        address marketplaceHelper,
        address jpeg
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
        DAWN_OF_INSRT = dawnOfInsrt;
        MARKETPLACE_HELPER = marketplaceHelper;
        JPEG = jpeg;
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

        if (!l.isEnabled) {
            revert ShardVault__NotEnabled();
        }

        uint16 maxSupply = l.maxSupply;
        uint16 balance = l.shardBalances[msg.sender];
        uint16 maxUserShards = l.maxUserShards;

        if (balance == maxUserShards) {
            revert ShardVault__MaxUserShards();
        }

        if (block.timestamp < l.whitelistEndsAt) {
            _enforceWhitelist(msg.sender);
            maxSupply = l.reservedShards;
        }

        uint256 amount = msg.value;
        uint256 shardValue = l.shardValue;
        uint16 totalSupply = l.totalSupply;

        if (amount % shardValue != 0 || amount == 0) {
            revert ShardVault__InvalidDepositAmount();
        }
        if (totalSupply == maxSupply || l.isInvested) {
            revert ShardVault__DepositForbidden();
        }

        uint16 shards = uint16(amount / shardValue);
        uint16 excessShards;

        if (balance + shards > maxUserShards) {
            excessShards = shards + balance - maxUserShards;
            shards -= excessShards;
        }

        if (shards + totalSupply > maxSupply) {
            excessShards += shards + totalSupply - maxSupply;
            shards = maxSupply - totalSupply;
        }

        l.totalSupply += shards;
        l.shardBalances[msg.sender] += shards;

        unchecked {
            for (uint256 i; i < shards; ++i) {
                IShardCollection(SHARD_COLLECTION).mint(
                    msg.sender,
                    _formatTokenId(uint96(++l.count))
                );
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

        if (l.isInvested || l.totalSupply == l.maxSupply) {
            revert ShardVault__WithdrawalForbidden();
        }

        uint16 tokens = uint16(tokenIds.length);
        _enforceSufficientBalance(msg.sender, tokens);

        unchecked {
            for (uint256 i; i < tokens; ++i) {
                _enforceShardOwnership(msg.sender, tokenIds[i]);
                _enforceVaultTokenIdMatch(tokenIds[i]);

                IShardCollection(SHARD_COLLECTION).burn(tokenIds[i]);
            }
        }

        l.totalSupply -= tokens;
        l.shardBalances[msg.sender] -= tokens;

        payable(msg.sender).sendValue(tokens * l.shardValue);
    }

    /**
     * @notice returns total minted shards amount
     * @return totalSupply total minted shards amount
     */
    function _totalSupply() internal view returns (uint16 totalSupply) {
        totalSupply = ShardVaultStorage.layout().totalSupply;
    }

    /**
     * @notice returns maximum possible minted shards
     * @return maxSupply maximum possible minted shards
     */
    function _maxSupply() internal view returns (uint16 maxSupply) {
        maxSupply = ShardVaultStorage.layout().maxSupply;
    }

    /**
     * @notice returns ETH value of a shard
     * @return shardValue ETH value of a shard
     */
    function _shardValue() internal view returns (uint256 shardValue) {
        shardValue = ShardVaultStorage.layout().shardValue;
    }

    /**
     * @notice return ShardCollection address
     * @return shardCollection address
     */
    function _shardCollection()
        internal
        view
        returns (address shardCollection)
    {
        shardCollection = SHARD_COLLECTION;
    }

    /**
     * @notice return minted token count
     * @dev does not reduce when tokens are burnt
     * @return count minted token count
     */
    function _count() internal view returns (uint16 count) {
        count = ShardVaultStorage.layout().count;
    }

    /**
     * @notice return isInvested flag state
     * @dev indicates whether last asset purchase has been made
     * @return isInvested isInvested flag
     */
    function _isInvested() internal view returns (bool isInvested) {
        isInvested = ShardVaultStorage.layout().isInvested;
    }

    /**
     * @notice return maxUserShards
     * @return maxUserShards maxUserShards value
     */
    function _maxUserShards() internal view returns (uint16 maxUserShards) {
        maxUserShards = ShardVaultStorage.layout().maxUserShards;
    }

    /**
     * @notice return vault shards owned by an account
     * @param account address owning shards
     * @return shardBalance shards owned by account
     */
    function _shardBalances(address account)
        internal
        view
        returns (uint16 shardBalance)
    {
        shardBalance = ShardVaultStorage.layout().shardBalances[account];
    }

    /**
     * @notice return amount of shards reserved for whitelist
     * @return reserverdShards amount of shards reserved for whitelist
     */
    function _reservedShards() internal view returns (uint16 reserverdShards) {
        reserverdShards = ShardVaultStorage.layout().reservedShards;
    }

    /**
     * @notice return array with owned token IDs
     * @return ownedTokenIds  array of owned token IDs
     */
    function _ownedTokenIds()
        internal
        view
        returns (uint256[] memory ownedTokenIds)
    {
        ownedTokenIds = ShardVaultStorage.layout().ownedTokenIds.toArray();
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
     * @param calls  array of EncodedCall structs containing information to execute necessary low level
     * calls to purchase a punk
     * @param punkId id of punk
     */
    function _purchasePunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId,
        bool isFinalPurchase
    ) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.collection != PUNKS) {
            revert ShardVault__CollectionNotPunks();
        }

        uint256 price = ICryptoPunkMarket(PUNKS)
            .punksOfferedForSale(punkId)
            .minValue;

        IMarketPlaceHelper(MARKETPLACE_HELPER).purchaseAsset{ value: price }(
            calls,
            address(0),
            price
        );

        if (l.ownedTokenIds.length() == 0) {
            l.isInvested = true;
        }
        l.accruedFees += (price * l.acquisitionFeeBP) / BASIS_POINTS;
        l.ownedTokenIds.add(punkId);

        if (isFinalPurchase) {
            l.cumulativeEPS +=
                (address(this).balance - l.accruedFees) /
                _totalSupply();
        }
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
        address jpegdVault = ShardVaultStorage.layout().jpegdVault;

        uint256 value = INFTVault(jpegdVault).getNFTValueUSD(punkId);

        pUSD = _collateralizePunk(
            punkId,
            borrowAmount,
            insure,
            jpegdVault,
            value,
            PUSD
        );
    }

    function _collateralizePunkPETH(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) internal returns (uint256 pETH) {
        address jpegdVault = ShardVaultStorage.layout().jpegdVault;

        uint256 value = INFTVault(jpegdVault).getNFTValueETH(punkId);

        pETH = _collateralizePunk(
            punkId,
            borrowAmount,
            insure,
            jpegdVault,
            value,
            PETH
        );
    }

    function _collateralizePunk(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure,
        address jpegdVault,
        uint256 value,
        address token
    ) private returns (uint256 amount) {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 creditLimit = INFTVault(jpegdVault).getCreditLimit(punkId);

        uint256 targetLTV = creditLimit -
            (value * (l.ltvBufferBP + l.ltvDeviationBP)) /
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

        amount = IERC20(token).balanceOf(address(this));
    }

    /**
     * @notice stakes an amount of pUSD into JPEGd autocompounder and then into JPEGd PUSD_CITADEL
     * @param amount amount of pUSD to stake
     * @param minCurveLP minimum LP to receive from pUSD staking into curve
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     * the pool to deposit into
     * @return shares deposited into JPEGd autocompounder
     */
    function _stakePUSD(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) internal returns (uint256 shares) {
        //pUSD is in position 0 in the curve meta pool
        shares = _stake(
            amount,
            minCurveLP,
            poolInfoIndex,
            PUSD,
            CURVE_PUSD_POOL,
            PUSD_CITADEL,
            [amount, 0]
        );
    }

    /**
     * @notice stakes an amount of pETH into JPEGd autocompounder and then into JPEGd PETH_CITADEL
     * @param amount amount of pETH to stake
     * @param minCurveLP minimum LP to receive from pETH staking into curve
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     * the pool to deposit into
     * @return shares deposited into JPEGd autocompounder
     */
    function _stakePETH(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex
    ) internal returns (uint256 shares) {
        //pETH is in position 1 in the curve meta pool
        shares = _stake(
            amount,
            minCurveLP,
            poolInfoIndex,
            PETH,
            CURVE_PETH_POOL,
            PETH_CITADEL,
            [0, amount]
        );
    }

    function _stake(
        uint256 amount,
        uint256 minCurveLP,
        uint256 poolInfoIndex,
        address token,
        address pool,
        address citadel,
        uint256[2] memory amounts
    ) private returns (uint256 shares) {
        IERC20(token).approve(pool, amount);
        uint256 curveLP = ICurveMetaPool(pool).add_liquidity(
            amounts,
            minCurveLP
        );

        IERC20(pool).approve(citadel, curveLP);
        shares = IVault(citadel).deposit(address(this), curveLP);

        IERC20(ILPFarming(LP_FARM).poolInfo(poolInfoIndex).lpToken).approve(
            LP_FARM,
            shares
        );

        ILPFarming(LP_FARM).deposit(poolInfoIndex, shares);
    }

    /**
     * @notice purchases and collateralizes a punk, and stakes all pUSD gained from collateralization
     * @param calls  array of EncodedCall structs containing information to execute necessary low level
     * calls to purchase a punk
     * @param punkId id of punk
     * @param minCurveLP minimum LP to receive from curve LP
     * @param borrowAmount amount to borrow
     * @param poolInfoIndex the index of the poolInfo struct in PoolInfo array corresponding to
     * the pool to deposit into
     * @param insure whether to insure
     * @param isFinalPurchase indicates whether this is the final purchase for the vault, to free up
     * any excess ETH for claiming
     */
    function _investPunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId,
        uint256 borrowAmount,
        uint256 minCurveLP,
        uint256 poolInfoIndex,
        bool insure,
        bool isFinalPurchase
    ) internal {
        _purchasePunk(calls, punkId, isFinalPurchase);
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
     * @notice unstakes from JPEG'd LPFarming, then from JPEG'd citadel, then from curve LP
     * @param amount amount of shares of auto-compounder to burn
     * @param minPUSD minimum pUSD to receive from curve pool
     * @param poolInfoIndex the index of the JPEG'd LPFarming pool
     * @return pUSD pUSD amount returned
     */
    function _unstakePUSD(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex
    ) internal returns (uint256 pUSD) {
        //pUSD is in position 0 in the curve meta pool
        pUSD = _unstake(
            amount,
            minPUSD,
            poolInfoIndex,
            PUSD_CITADEL,
            CURVE_PUSD_POOL,
            0
        );
    }

    /**
     * @notice unstakes from JPEG'd LPFarming, then from JPEG'd citadel, then from curve LP
     * @param amount amount of shares of auto-compounder to burn
     * @param minPETH minimum pETH to receive from curve pool
     * @param poolInfoIndex the index of the JPEG'd LPFarming pool
     * @return pETH pETH amount returned
     */
    function _unstakePETH(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex
    ) internal returns (uint256 pETH) {
        //pETH is in position 1 in the curve meta pool
        pETH = _unstake(
            amount,
            minPETH,
            poolInfoIndex,
            PETH_CITADEL,
            CURVE_PETH_POOL,
            1
        );
    }

    function _unstake(
        uint256 autoCompAmount,
        uint256 minTokenAmount,
        uint256 poolInfoIndex,
        address citadel,
        address pool,
        int128 curveID
    ) internal returns (uint256 tokenAmount) {
        ILPFarming(LP_FARM).withdraw(poolInfoIndex, autoCompAmount);

        uint256 curveLP = IVault(citadel).withdraw(
            address(this),
            IERC20(ILPFarming(LP_FARM).poolInfo(poolInfoIndex).lpToken)
                .balanceOf(address(this))
        );

        tokenAmount = ICurveMetaPool(pool).remove_liquidity_one_coin(
            curveLP,
            curveID,
            minTokenAmount
        );
    }

    /**
     * @notice liquidates all staked tokens in order to pay back loan, retrieves collateralized punk
     * @param punkId id of punk position pertains to
     * @param minTokenAmount minimum token (pETH/pUSD) to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param isPUSD indicates whether loan position is denominated in pUSD or pETH
     */
    function _closePunkPosition(
        uint256 punkId,
        uint256 minTokenAmount,
        uint256 poolInfoIndex,
        bool isPUSD
    ) internal {
        address jpegdVault = ShardVaultStorage.layout().jpegdVault;
        uint256 debt = _totalDebt(jpegdVault, punkId);
        if (isPUSD) {
            _unstakePUSD(
                ILPFarming(LP_FARM)
                    .userInfo(poolInfoIndex, address(this))
                    .amount,
                minTokenAmount,
                poolInfoIndex
            );
            IERC20(PUSD).approve(jpegdVault, debt);
        } else {
            _unstakePETH(
                ILPFarming(LP_FARM)
                    .userInfo(poolInfoIndex, address(this))
                    .amount,
                minTokenAmount,
                poolInfoIndex
            );
            IERC20(PETH).approve(jpegdVault, debt);
        }
        INFTVault(jpegdVault).repay(punkId, debt);
        INFTVault(jpegdVault).closePosition(punkId);
    }

    /**
     * @notice lists a punk on CryptoPunk market place using MarketPlaceHelper contract
     * @param calls encoded call array for listing the punk
     * @param punkId id of punk to list
     */
    function _listPunk(
        IMarketPlaceHelper.EncodedCall[] memory calls,
        uint256 punkId
    ) internal {
        ICryptoPunkMarket(PUNKS).transferPunk(MARKETPLACE_HELPER, punkId);
        IMarketPlaceHelper(MARKETPLACE_HELPER).listAsset(calls);
    }

    /**
     * @notice makes a debt payment for a collateralized NFT in jpeg'd
     * @param amount amount of pUSD intended to be repaid
     * @param minPUSD minimum pUSD to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param punkId id of punk position pertains to
     * @return paidDebt amount of debt repaid
     */
    function _repayLoanPUSD(
        uint256 amount,
        uint256 minPUSD,
        uint256 poolInfoIndex,
        uint256 punkId
    ) internal returns (uint256 paidDebt) {
        address jpegdVault = ShardVaultStorage.layout().jpegdVault;

        uint256 autoComp = _queryAutoCompForPUSD(amount);
        paidDebt = _unstakePUSD(autoComp, minPUSD, poolInfoIndex);

        if (amount > paidDebt) {
            revert ShardVault__DownPaymentInsufficient();
        }

        IERC20(PUSD).approve(jpegdVault, paidDebt);
        INFTVault(jpegdVault).repay(punkId, paidDebt);
    }

    /**
     * @notice makes a debt payment for a collateralized NFT in jpeg'd
     * @param amount amount of pETH intended to be repaid
     * @param minPETH minimum pETH to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param punkId id of punk position pertains to
     * @return paidDebt amount of debt repaid
     */
    function _repayLoanPETH(
        uint256 amount,
        uint256 minPETH,
        uint256 poolInfoIndex,
        uint256 punkId
    ) internal returns (uint256 paidDebt) {
        address jpegdVault = ShardVaultStorage.layout().jpegdVault;

        uint256 autoComp = _queryAutoCompForPETH(amount);
        paidDebt = _unstakePETH(autoComp, minPETH, poolInfoIndex);

        if (amount > paidDebt) {
            revert ShardVault__DownPaymentInsufficient();
        }

        IERC20(PETH).approve(jpegdVault, paidDebt);
        INFTVault(jpegdVault).repay(punkId, paidDebt);
    }

    /**
     * @notice makes loan repayment without unstaking
     * @param token payment token
     * @param amount payment amount
     * @param punkId id of punk
     */
    function _directRepayLoan(
        address token,
        uint256 amount,
        uint256 punkId
    ) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        IERC20(token).approve(l.jpegdVault, amount);
        INFTVault(l.jpegdVault).repay(punkId, amount);
    }

    /**
     * @notice returns amount of AutoComp LP shares needed to be burnt during unstaking
     * to result in a given amount of pUSD
     * @param pUSD desired pUSD amount
     * @return autoComp required AutoComp LP shares
     */
    function _queryAutoCompForPUSD(uint256 pUSD)
        internal
        view
        returns (uint256 autoComp)
    {
        //note: does not account for fees, not meant for precise calculations.
        //      this is alright because it acts as a small 'buffer' to the amount
        //      necessary for the downpayment to impact the debt as intended
        uint256 curveLP = ICurveMetaPool(CURVE_PUSD_POOL).calc_token_amount(
            [pUSD, 0],
            false
        );

        //note: accounts for fees; ball-parks
        uint256 curveLPAccountingFee = (curveLP *
            ShardVaultStorage.layout().conversionBuffer) / (BASIS_POINTS * 100);

        autoComp =
            (curveLPAccountingFee * 10**IVault(PUSD_CITADEL).decimals()) /
            IVault(PUSD_CITADEL).exchangeRate();
    }

    /**
     * @notice returns amount of AutoComp LP shares needed to be burnt during unstaking
     * to result in a given amount of pETH
     * @param pETH desired pETH amount
     * @return autoComp required AutoComp LP shares
     */
    function _queryAutoCompForPETH(uint256 pETH)
        internal
        view
        returns (uint256 autoComp)
    {
        //note: does not account for fees, not meant for precise calculations.
        //      this is alright because it acts as a small 'buffer' to the amount
        //      necessary for the downpayment to impact the debt as intended
        uint256 curveLP = ICurveMetaPool(CURVE_PETH_POOL).calc_token_amount(
            [0, pETH],
            false
        );

        //note: accounts for fees; ball-parks     //conversion_buffer
        uint256 curveLPAccountingFee = (curveLP *
            ShardVaultStorage.layout().conversionBuffer) / (100 * BASIS_POINTS);

        autoComp =
            (curveLPAccountingFee * 10**IVault(PETH_CITADEL).decimals()) /
            IVault(PETH_CITADEL).exchangeRate();
    }

    /**
     * @notice withdraws any proceeds generated from punk sales
     * @param punkId the index of the punk proceeds were generated by
     */
    function _withdrawPunkProceeds(uint256 punkId) internal {
        ICryptoPunkMarket(PUNKS).withdraw();
        ShardVaultStorage.layout().ownedTokenIds.remove(punkId);
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

    /**
     * @notice sets the maxSupply of shards
     * @param maxSupply the maxSupply of shards
     */
    function _setMaxSupply(uint16 maxSupply) internal {
        ShardVaultStorage.layout().maxSupply = maxSupply;
    }

    /**
     * @notice provides (makes available) yield in the form of ETH and JPEG tokens
     * @dev unstakes some of the pETH position to convert to yield, and claims
     * pending rewards in LP_FARM to receive JPEG
     * @param autoComp amount of autoComp tokens to unstake
     * @param minETH minimum ETH to receive after unstaking
     * @param poolInfoIndex the index of the LP_FARM pool which corresponds to staking PETH-ETH curveLP
     * @return providedETH total ETH provided as yield
     * @return providedJPEG total JEPG provided as yield
     */
    function _provideYieldPETH(
        uint256 autoComp,
        uint256 minETH,
        uint256 poolInfoIndex
    ) internal returns (uint256 providedETH, uint256 providedJPEG) {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        providedETH = _unstake(
            autoComp,
            minETH,
            poolInfoIndex,
            PETH_CITADEL,
            CURVE_PETH_POOL,
            int128(0) //ETH index in curve pool
        );

        providedJPEG = ILPFarming(LP_FARM).pendingReward(
            poolInfoIndex,
            address(this)
        );
        ILPFarming(LP_FARM).claim(poolInfoIndex);

        if (!l.isYieldClaiming) {
            l.isYieldClaiming = true;
        }

        l.cumulativeEPS += providedETH / l.totalSupply;
        l.cumulativeJPS += providedJPEG / l.totalSupply;
    }

    /**
     * @notice returns excess ETH left over after vault has invested
     * @param account address making the claim
     * @param tokenIds array of shard IDs to claim with
     */
    function _claimExcessETH(address account, uint256[] memory tokenIds)
        internal
    {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 tokens = tokenIds.length;

        _enforceNotYieldClaimingAndInvested();
        _enforceSufficientBalance(account, tokens);

        uint256 cumulativeEPS = l.cumulativeEPS;
        uint256 totalETH;
        uint256 claimedEPS;

        unchecked {
            for (uint256 i; i < tokens; ++i) {
                _enforceShardOwnership(account, tokenIds[i]);
                _enforceVaultTokenIdMatch(tokenIds[i]);

                claimedEPS = cumulativeEPS - l.claimedEPS[tokenIds[i]];
                totalETH += claimedEPS;
                l.claimedEPS[tokenIds[i]] += claimedEPS;
            }
        }

        payable(account).sendValue(totalETH);
    }

    /**
     * @notice sends yield in the form of ETH + JPEG tokens to account
     * @param account address making the yield claim
     * @param tokenIds array of shard IDs to claim with
     */
    function _claimYield(address account, uint256[] memory tokenIds) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 tokens = tokenIds.length;

        _enforceYieldClaiming();
        _enforceSufficientBalance(account, tokens);

        //parameters for ETH claiming
        uint256 cumulativeEPS = l.cumulativeEPS;
        uint256 totalETH;
        uint256 claimedEPS;
        //parameters for JPEG claiming
        uint256 cumulativeJPS = l.cumulativeJPS;
        uint256 totalJPEG;
        uint256 claimedJPS;

        unchecked {
            for (uint256 i; i < tokens; ++i) {
                _enforceShardOwnership(account, tokenIds[i]);
                _enforceVaultTokenIdMatch(tokenIds[i]);

                //account for claimable ETH
                claimedEPS = cumulativeEPS - l.claimedEPS[tokenIds[i]];
                totalETH += claimedEPS;
                l.claimedEPS[tokenIds[i]] += claimedEPS;

                //account for claimable JPEG
                claimedJPS = cumulativeJPS - l.claimedJPS[tokenIds[i]];
                totalJPEG += claimedJPS;
                l.claimedJPS[tokenIds[i]] += claimedJPS;
            }
        }

        //apply fees
        uint256 ETHfee = (totalETH * l.yieldFeeBP) / BASIS_POINTS;
        l.accruedFees += ETHfee;

        uint256 jpegFee = (totalJPEG * l.yieldFeeBP) / BASIS_POINTS;
        l.accruedJPEG += jpegFee;

        //transfer yield
        IERC20(JPEG).transfer(account, totalJPEG - jpegFee);
        payable(account).sendValue(totalETH - ETHfee);
    }

    /**
     * @notice before shard transfer hook
     * @dev only SHARD_COLLECTION proxy may call - purpose is to maintain correct balances
     * @param from address transferring
     * @param to address receiving
     */
    function _beforeShardTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (msg.sender != SHARD_COLLECTION) {
            revert ShardVault__NotShardCollection();
        }

        uint256[] memory tokenIds;
        uint256[] memory temp = new uint256[](1);
        temp[0] = tokenId;
        tokenIds = temp;

        if (from != address(0)) {
            if (l.isYieldClaiming) {
                _claimYield(from, tokenIds);
            }

            if (!l.isYieldClaiming && l.isInvested) {
                _claimExcessETH(from, tokenIds);
            }

            --l.shardBalances[from];
        }

        ++l.shardBalances[to];
    }

    /**
     * @notice sets the whitelistEndsAt timestamp
     * @param whitelistEndsAt timestamp of whitelist end
     */
    function _setWhitelistEndsAt(uint64 whitelistEndsAt) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        l.whitelistEndsAt = whitelistEndsAt;
    }

    /**
     * @notice sets the maximum amount of shard to be minted during whitelist
     * @param reservedShards whitelist shard amount
     */
    function _setReservedShards(uint16 reservedShards) internal {
        ShardVaultStorage.layout().reservedShards = reservedShards;
    }

    /**
     * @notice sets the isEnabled flag
     * @param isEnabled boolean value
     */
    function _setIsEnabled(bool isEnabled) internal {
        ShardVaultStorage.layout().isEnabled = isEnabled;
    }

    /**
     * @notice return the maximum shards a user is allowed to mint
     * @dev theoretically a user may acquire more than this amount via transfers, but once this amount is exceeded
     * said user may not deposit more
     * @param maxUserShards new maxUserShards value
     */
    function _setMaxUserShards(uint16 maxUserShards) internal {
        ShardVaultStorage.layout().maxUserShards = maxUserShards;
    }

    /**
     * @notice returns sum of total fees (sale, yield, acquisition) accrued over the entire lifetime of the vault
     * @dev accounts for fee withdrawals
     * @return fees accrued fees
     */
    function _accruedFees() internal view returns (uint256 fees) {
        fees = ShardVaultStorage.layout().accruedFees;
    }

    /**
     * @notice returns sum of total jpeg due to yield fee accrued over the entire lifetime of the vault
     * @dev accounts for jpeg withdrawals
     * @return jpeg accrued jpeg
     */
    function _accruedJPEG() internal view returns (uint256 jpeg) {
        jpeg = ShardVaultStorage.layout().accruedJPEG;
    }

    /**
     * @notice returns acquisition fee BP
     * @return acquisitionFeeBP basis points of acquisition fee
     */
    function _acquisitionFeeBP()
        internal
        view
        returns (uint16 acquisitionFeeBP)
    {
        acquisitionFeeBP = ShardVaultStorage.layout().acquisitionFeeBP;
    }

    /**
     * @notice returns sale fee BP
     * @return saleFeeBP basis points of sale fee
     */
    function _saleFeeBP() internal view returns (uint16 saleFeeBP) {
        saleFeeBP = ShardVaultStorage.layout().saleFeeBP;
    }

    /**
     * @notice returns yield fee BP
     * @return yieldFeeBP basis points of yield fee
     */
    function _yieldFeeBP() internal view returns (uint16 yieldFeeBP) {
        yieldFeeBP = ShardVaultStorage.layout().yieldFeeBP;
    }

    /**
     * @notice returns the amount of shards a given account has left to mint
     * @param account address to calculate for
     * @return shards the amount of shards the account may mint
     */
    function _userRemainingShards(address account)
        internal
        view
        returns (uint256 shards)
    {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        if (l.maxUserShards > l.shardBalances[account]) {
            shards = l.maxUserShards - l.shardBalances[account];
        }
    }

    /**
     * @notice returns how many remaining reservations for shards are left
     * @dev returns 0 if whitelist period has elapsed
     * @return shards the amount of remaining shard reservations
     */
    function _remainingShardReservations()
        internal
        view
        returns (uint256 shards)
    {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        if (block.timestamp < l.whitelistEndsAt) {
            shards = l.maxSupply - l.totalSupply;
        }
    }

    /**
     * @notice returns vault-wide amount of shards that can still be minted
     * @return shards amount of shards which can still be minted
     */
    function _remainingShards() internal view returns (uint256 shards) {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        shards = l.maxSupply - l.totalSupply;
    }

    /**
     * @notice check to ensure account is whitelisted (holding a DAWN_OF_INSRT token)
     * @param account address to check
     */
    function _enforceWhitelist(address account) internal view {
        if (IERC721(DAWN_OF_INSRT).balanceOf(account) == 0) {
            revert ShardVault__NotWhitelisted();
        }
    }

    /**
     * @notice returns address of market place helper
     * @return MARKETPLACE_HELPER address
     */
    function _marketplaceHelper() internal view returns (address) {
        return MARKETPLACE_HELPER;
    }

    /**
     * @notice returns the JPEG claimed by a given shard
     * @param shardId id of shard to check
     * @return claimedJPS claimed JPEG for given shard
     */
    function _claimedJPS(uint256 shardId)
        internal
        view
        returns (uint256 claimedJPS)
    {
        claimedJPS = ShardVaultStorage.layout().claimedJPS[shardId];
    }

    /**
     * @notice returns the ETH claimed by a given shard
     * @param shardId id of shard to check
     * @return claimedEPS claimed ETH for given shard
     */
    function _claimedEPS(uint256 shardId)
        internal
        view
        returns (uint256 claimedEPS)
    {
        claimedEPS = ShardVaultStorage.layout().claimedEPS[shardId];
    }

    /**
     * @notice returns the cumulative JPEG per shard value
     * @return cumulativeJPS cumulative JPEG per shard value
     */
    function _cumulativeJPS() internal view returns (uint256 cumulativeJPS) {
        cumulativeJPS = ShardVaultStorage.layout().cumulativeJPS;
    }

    /**
     * @notice returns the cumulative ETH per shard value
     * @return cumulativeEPS cumulative ETH per shard value
     */
    function _cumulativeEPS() internal view returns (uint256 cumulativeEPS) {
        cumulativeEPS = ShardVaultStorage.layout().cumulativeEPS;
    }

    /**
     * @notice returns the yield claiming status of the vault
     * @return isYieldClaiming the yield claiming status of the vault
     */
    function _isYieldClaiming() internal view returns (bool isYieldClaiming) {
        isYieldClaiming = ShardVaultStorage.layout().isYieldClaiming;
    }

    /**
     * @notice check to ensure account owns a given tokenId corresponding to a shard
     * @param account address to check
     * @param tokenId tokenId to check
     */
    function _enforceShardOwnership(address account, uint256 tokenId)
        internal
        view
    {
        if (IShardCollection(SHARD_COLLECTION).ownerOf(tokenId) != account) {
            revert ShardVault__NotShardOwner();
        }
    }

    /**
     * @notice check to ensure tokenId corresponds to vault
     * @param tokenId tokenId to check
     */
    function _enforceVaultTokenIdMatch(uint256 tokenId) internal view {
        (address vault, ) = _parseTokenId(tokenId);
        if (vault != address(this)) {
            revert ShardVault__VaultTokenIdMismatch();
        }
    }

    /**
     * @notice check to ensure an account has a balance larger than amount
     * @param account address to check
     * @param amount amount to check
     */
    function _enforceSufficientBalance(address account, uint256 amount)
        internal
        view
    {
        if (ShardVaultStorage.layout().shardBalances[account] < amount) {
            revert ShardVault__InsufficientShards();
        }
    }

    /**
     * @notice check to ensure yield claiming is initialized
     */
    function _enforceYieldClaiming() internal view {
        if (!ShardVaultStorage.layout().isYieldClaiming) {
            revert ShardVault__YieldClaimingForbidden();
        }
    }

    /**
     * @notice check to ensure yield claiming is not initialized and vault is invested
     */
    function _enforceNotYieldClaimingAndInvested() internal view {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        if (!l.isYieldClaiming && l.isInvested) {
            revert ShardVault__ClaimingExcessETHForbidden();
        }
    }

    /**
     * @notice enforces that a value cannot exceed BASIS_POINTS
     * @param value the value to check
     */
    function _enforceBasis(uint16 value) internal pure {
        if (value > 10000) revert ShardVault__BasisExceeded();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';

import { Errors } from './Errors.sol';
import { ICryptoPunkMarket } from '../cryptopunk/ICryptoPunkMarket.sol';
import { ICurveMetaPool } from '../curve/ICurveMetaPool.sol';
import { ILPFarming } from '../jpegd/ILPFarming.sol';
import { INFTVault } from '../jpegd/INFTVault.sol';
import { IVault } from '../jpegd/IVault.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';

//CHECK IF ALL VAULTS USE PUSD OR IF SOME HAVE BUSD eg

/**
 * @title Shard Vault internal functions
 * @dev inherited by all Shard Vault implementation contracts
 */
abstract contract ShardVaultInternal is OwnableInternal {
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    address internal immutable PUSD;
    address internal immutable PUNKS;
    address internal immutable CITADEL;
    address internal immutable LP_FARM;
    address internal immutable CURVE_PUSD_POOL;
    uint256 internal immutable INTEREST_BUFFER;
    uint256 internal constant BASIS_POINTS = 10000;

    constructor(
        address pUSD,
        address punkMarket,
        address citadel,
        address lpFarm,
        address curvePUSDPool,
        uint256 interestBuffer,
        uint256 salesFeeBP,
        uint256 fundraiseFeeBP,
        uint256 yieldFeeBP
    ) {
        PUNKS = punkMarket;
        PUSD = pUSD;
        CITADEL = citadel;
        LP_FARM = lpFarm;
        CURVE_PUSD_POOL = curvePUSDPool;
        INTEREST_BUFFER = interestBuffer;

        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        l.salesFeeBP = salesFeeBP;
        l.fundraiseFeeBP = fundraiseFeeBP;
        l.yieldFeeBP = yieldFeeBP;
    }

    /**
     * @notice ensure caller is protocol owner
     */
    function _onlyProtocolOwner() internal view {
        if (msg.sender != _protocolOwner()) revert Errors.NotProtocolOwner();
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
        } // probably remove this error

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
        uint256 minCurveLP,
        bool insure
    ) internal {
        if (l.ownedTokenIds.length() == 0) {
            _collectFee(l, l.fundraiseFeeBP);
        }
        _purchasePunk(l, punkId);
        l.ownedTokenIds.add(punkId);
        _stake(l, _collateralizePunk(l, punkId, insure), minCurveLP);
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
        if (feeBP > 10000) revert Errors.BasisExceeded();
        ShardVaultStorage.layout().salesFeeBP = feeBP;
    }

    /**
     * @notice sets the fundraise fee BP
     * @param feeBP basis points value of fee
     */
    function _setFundraiseFee(uint256 feeBP) internal {
        if (feeBP > 10000) revert Errors.BasisExceeded();
        ShardVaultStorage.layout().fundraiseFeeBP = feeBP;
    }

    /**
     * @notice sets the Yield fee BP
     * @param feeBP basis points value of fee
     */
    function _setYieldFee(uint256 feeBP) internal {
        if (feeBP > 10000) revert Errors.BasisExceeded();
        ShardVaultStorage.layout().yieldFeeBP = feeBP;
    }

    /**
     * @notice unstakes from JPEG,d auto-compounder, then from JPEG'd citadel, then from curve LP
     * @param l storage layout
     * @param amount amount of shares of auto-compounder to burn
     * @param minPUSD minimum pUSD to receive from curve pool
     * @return pUSD pUSD amount returned
     */
    function _unstake(
        ShardVaultStorage.Layout storage l,
        uint256 amount,
        uint256 minPUSD
    ) internal returns (uint256 pUSD) {
        ILPFarming(LP_FARM).withdraw(1, amount);
        uint256 citadelLP = IVault(CITADEL).withdraw(
            address(this),
            IERC20(ILPFarming(LP_FARM).poolInfo()[1].lpToken).balanceOf(
                address(this)
            )
        );

        //note: can remove initialCurveLP functionality, ask Daniel
        uint256 initialCurveLP = IERC20(CURVE_PUSD_POOL).balanceOf(
            address(this)
        );

        ILPFarming(LP_FARM).withdraw(l.citadelId, citadelLP);
        ILPFarming(LP_FARM).claim(l.citadelId);

        uint256 curveLP = IERC20(CURVE_PUSD_POOL).balanceOf(address(this)) -
            initialCurveLP;

        pUSD = ICurveMetaPool(CURVE_PUSD_POOL).remove_liquidity_one_coin(
            curveLP,
            0, //id of pUSD in curve pool
            minPUSD
        );
    }

    function _closePunkPosition(
        ShardVaultStorage.Layout storage l,
        uint256 tokenId,
        uint256 minPUSD,
        uint256 ask
    ) internal {
        _unstake(
            l,
            ILPFarming(LP_FARM).userInfo(l.citadelId, address(this)).amount,
            minPUSD
        );

        uint256 debt = _totalDebt(l, tokenId);

        IERC20(PUSD).approve(l.jpegdVault, debt + INTEREST_BUFFER);
        INFTVault(l.jpegdVault).repay(tokenId, debt + INTEREST_BUFFER);
        INFTVault(l.jpegdVault).closePosition(tokenId);

        ICryptoPunkMarket(PUNKS).offerPunkForSale(tokenId, ask);
    }

    function _totalDebt(ShardVaultStorage.Layout storage l, uint256 tokenId)
        internal
        view
        returns (uint256 debt)
    {
        debt =
            INFTVault(l.jpegdVault).getDebtInterest(tokenId) +
            INFTVault(l.jpegdVault).positions(tokenId).debtPrincipal;
    }
}

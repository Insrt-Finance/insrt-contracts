// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { AddressUtils } from '@solidstate/contracts/utils/AddressUtils.sol';
import { EnumerableSet } from '@solidstate/contracts/data/EnumerableSet.sol';
import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IERC173 } from '@solidstate/contracts/interfaces/IERC173.sol';
import { IERC721 } from '@solidstate/contracts/interfaces/IERC721.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { ERC721BaseInternal } from '@solidstate/contracts/token/ERC721/base/ERC721BaseInternal.sol';
import { ERC721EnumerableInternal } from '@solidstate/contracts/token/ERC721/enumerable/ERC721EnumerableInternal.sol';
import { ERC721MetadataStorage } from '@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol';

import { IShardVaultInternal } from './IShardVaultInternal.sol';
import { ShardVaultStorage } from './ShardVaultStorage.sol';
import { ICryptoPunkMarket } from '../interfaces/cryptopunk/ICryptoPunkMarket.sol';
import { ICurveMetaPool } from '../interfaces/curve/ICurveMetaPool.sol';
import { IJpegCardsCigStaking } from '../interfaces/jpegd/IJpegCardsCigStaking.sol';
import { IDawnOfInsrt } from '../interfaces/insrt/IDawnOfInsrt.sol';
import { ILPFarming } from '../interfaces/jpegd/ILPFarming.sol';
import { INFTEscrow } from '../interfaces/jpegd/INFTEscrow.sol';
import { INFTVault } from '../interfaces/jpegd/INFTVault.sol';
import { IVault } from '../interfaces/jpegd/IVault.sol';
import { IMarketPlaceHelper } from '../helpers/IMarketPlaceHelper.sol';

/**
 * @title Shard Vault internal functions
 * @dev inherited by all Shard Vault implementation contracts
 */
abstract contract ShardVaultInternal is
    IShardVaultInternal,
    OwnableInternal,
    ERC721BaseInternal,
    ERC721EnumerableInternal
{
    using AddressUtils for address payable;
    using EnumerableSet for EnumerableSet.UintSet;

    address internal immutable PUSD;
    address internal immutable PETH;
    address internal immutable JPEG;
    address internal immutable PUNKS;
    address internal immutable PUSD_CITADEL;
    address internal immutable PETH_CITADEL;
    address internal immutable LP_FARM;
    address internal immutable CURVE_PUSD_POOL;
    address internal immutable CURVE_PETH_POOL;
    address internal immutable MARKETPLACE_HELPER;
    address internal immutable JPEG_CARDS_CIG_STAKING;
    address internal immutable JPEG_CARDS;
    address internal immutable DAWN_OF_INSRT;
    address internal immutable TREASURY;
    uint256 internal constant BASIS_POINTS = 10000;
    uint256 internal constant CURVE_BASIS = 10000000000;
    uint256 internal constant CURVE_FEE = 4000000;
    uint256 internal constant TIER0_FEE_COEFFICIENT = 9000;
    uint256 internal constant TIER1_FEE_COEFFICIENT = 7500;
    uint256 internal constant TIER2_FEE_COEFFICIENT = 6000;
    uint256 internal constant TIER3_FEE_COEFFICIENT = 4000;
    uint256 internal constant TIER4_FEE_COEFFICIENT = 2000;

    constructor(
        JPEGParams memory jpegParams,
        AuxiliaryParams memory auxiliaryParams
    ) {
        PUSD = jpegParams.PUSD;
        PETH = jpegParams.PETH;
        PUSD_CITADEL = jpegParams.PUSD_CITADEL;
        PETH_CITADEL = jpegParams.PETH_CITADEL;
        LP_FARM = jpegParams.LP_FARM;
        CURVE_PUSD_POOL = jpegParams.CURVE_PUSD_POOL;
        CURVE_PETH_POOL = jpegParams.CURVE_PETH_POOL;
        JPEG = jpegParams.JPEG;
        JPEG_CARDS_CIG_STAKING = jpegParams.JPEG_CARDS_CIG_STAKING;
        JPEG_CARDS = jpegParams.JPEG_CARDS;

        PUNKS = auxiliaryParams.PUNKS;
        DAWN_OF_INSRT = auxiliaryParams.DAWN_OF_INSRT;
        MARKETPLACE_HELPER = auxiliaryParams.MARKETPLACE_HELPER;
        TREASURY = auxiliaryParams.TREASURY;
    }

    modifier onlyProtocolOwner() {
        _onlyProtocolOwner(msg.sender);
        _;
    }

    modifier onlyAuthorized() {
        _onlyAuthorized(msg.sender);
        _;
    }

    function _onlyProtocolOwner(address account) internal view {
        if (account != _protocolOwner()) {
            revert ShardVault__NotProtocolOwner();
        }
    }

    function _onlyAuthorized(address account) internal view {
        if (
            account != _protocolOwner() &&
            ShardVaultStorage.layout().authorized[account] == false
        ) {
            revert ShardVault__NotAuthorized();
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
     * @notice deposits ETH in exchange for shards
     */
    function _deposit() internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (!l.isEnabled) {
            revert ShardVault__NotEnabled();
        }

        uint64 maxSupply = l.maxSupply;
        uint64 maxMintBalance = l.maxMintBalance;
        uint256 balance = _balanceOf(msg.sender);

        if (balance >= maxMintBalance) {
            revert ShardVault__MaxMintBalance();
        }

        if (block.timestamp < l.whitelistEndsAt) {
            _enforceWhitelist(msg.sender);
            maxSupply = l.reservedSupply;
        }

        uint256 amount = msg.value;
        uint256 shardValue = l.shardValue;
        uint256 totalSupply = _totalSupply();

        if (amount % shardValue != 0 || amount == 0) {
            revert ShardVault__InvalidDepositAmount();
        }
        if (totalSupply == maxSupply || l.isInvested) {
            revert ShardVault__DepositForbidden();
        }

        uint256 shards = amount / shardValue;
        uint256 excessShards;

        if (balance + shards > maxMintBalance) {
            excessShards = shards + balance - maxMintBalance;
            shards -= excessShards;
        }

        if (shards + totalSupply > maxSupply) {
            excessShards += shards + totalSupply - maxSupply;
            shards = maxSupply - totalSupply;
        }

        unchecked {
            uint256 count = l.totalMintCount;
            for (uint256 i = 1; i <= shards; ++i) {
                _mint(msg.sender, count + i);
            }
            l.totalMintCount += uint64(shards);
        }

        if (excessShards > 0) {
            payable(msg.sender).sendValue(excessShards * shardValue);
        }
    }

    /**
     * @notice burn held shards before NFT acquisition and withdraw corresponding ETH
     * @param shardIds list of ids of shards to burn
     */
    function _withdraw(uint256[] memory shardIds) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.isInvested || _totalSupply() == l.maxSupply) {
            revert ShardVault__WithdrawalForbidden();
        }

        uint16 shards = uint16(shardIds.length);
        _enforceSufficientBalance(msg.sender, shards);

        unchecked {
            for (uint256 i; i < shards; ++i) {
                uint256 shardId = shardIds[i];
                _enforceShardOwnership(msg.sender, shardId);
                _burn(shardId);
            }
        }

        payable(msg.sender).sendValue(shards * l.shardValue);
    }

    /**
     * @notice returns maximum possible minted shards
     * @return maxSupply maximum possible minted shards
     */
    function _maxSupply() internal view returns (uint64 maxSupply) {
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
     * @notice return isInvested flag state; indicates whether last asset purchase has been made
     * @return isInvested isInvested flag
     */
    function _isInvested() internal view returns (bool isInvested) {
        isInvested = ShardVaultStorage.layout().isInvested;
    }

    /**
     * @notice return amount of shards reserved for whitelist
     * @return reserverdShards amount of shards reserved for whitelist
     */
    function _reservedSupply() internal view returns (uint64 reserverdShards) {
        reserverdShards = ShardVaultStorage.layout().reservedSupply;
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
     * @notice purchases a punk from CryptoPunkMarket
     * @param calls  array of EncodedCall structs containing information to execute necessary low level
     * calls to purchase a punk
     * @param punkId id of punk
     */
    function _purchasePunk(
        IMarketPlaceHelper.EncodedCall[] calldata calls,
        uint256 punkId
    ) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.collection != PUNKS) {
            revert ShardVault__CollectionNotPunks();
        }

        uint256 price = ICryptoPunkMarket(PUNKS)
            .punksOfferedForSale(punkId)
            .minValue;

        IMarketPlaceHelper(l.marketPlaceHelper).purchaseAsset{ value: price }(
            calls,
            address(0),
            price
        );

        if (l.ownedTokenIds.length() == 0) {
            l.isInvested = true;
        }
        l.accruedFees += (price * l.acquisitionFeeBP) / BASIS_POINTS;
        l.ownedTokenIds.add(punkId);
        emit PurchasePunk(punkId);
    }

    /**
     * @notice makes the any ETH besides the vault accrued fees claimable
     */
    function _makeUnusedETHClaimable() internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        l.cumulativeETHPerShard +=
            (address(this).balance - l.accruedFees) /
            _totalSupply();

        emit MakeUnusedETHClaimable();
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
        _enforceIsPUSDVault();

        pUSD = _collateralizePunk(
            punkId,
            borrowAmount,
            insure,
            l.jpegdVault,
            PUSD
        );

        emit CollateralizePunkPUSD(pUSD);
    }

    function _collateralizePunkPETH(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure
    ) internal returns (uint256 pETH) {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        _enforceIsPETHVault();

        pETH = _collateralizePunk(
            punkId,
            borrowAmount,
            insure,
            l.jpegdVault,
            PETH
        );

        emit CollaterlizePunkPETH(pETH);
    }

    function _collateralizePunk(
        uint256 punkId,
        uint256 borrowAmount,
        bool insure,
        address jpegdVault,
        address token
    ) private returns (uint256 amount) {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 creditLimit = INFTVault(jpegdVault).getCreditLimit(
            address(this),
            punkId
        );

        uint256 targetLTV = creditLimit -
            (creditLimit * (l.ltvBufferBP + l.ltvDeviationBP)) /
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

        uint256 oldBalance = IERC20(token).balanceOf(address(this));

        INFTVault(jpegdVault).borrow(punkId, borrowAmount, insure);

        amount = IERC20(token).balanceOf(address(this)) - oldBalance;
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
        _enforceIsPUSDVault();
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
        emit StakePUSD(shares);
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
        _enforceIsPETHVault();
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
        emit StakePETH(shares);
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
     * @notice withdraw JPEG and ETH accrued protocol fees, and send to TREASURY address
     * @return feesETH total ETH fees withdrawn
     * @return feesJPEG total JPEG fees withdrawn
     */
    function _withdrawFees()
        internal
        returns (uint256 feesETH, uint256 feesJPEG)
    {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        feesETH = l.accruedFees;
        feesJPEG = l.accruedJPEG;

        l.accruedFees -= feesETH;
        l.accruedJPEG -= feesJPEG;

        IERC20(JPEG).transfer(TREASURY, feesJPEG);
        payable(TREASURY).sendValue(feesETH);
        emit WithdrawFees(feesETH, feesJPEG);
    }

    /**
     * @notice sets the sale fee BP
     * @param feeBP basis points value of fee
     */
    function _setSaleFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        ShardVaultStorage.layout().saleFeeBP = feeBP;
        emit SetSaleFee(feeBP);
    }

    /**
     * @notice sets the acquisition fee BP
     * @param feeBP basis points value of fee
     */
    function _setAcquisitionFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        ShardVaultStorage.layout().acquisitionFeeBP = feeBP;
        emit SetAcquisitionFee(feeBP);
    }

    /**
     * @notice sets the Yield fee BP
     * @param feeBP basis points value of fee
     */
    function _setYieldFee(uint16 feeBP) internal {
        _enforceBasis(feeBP);
        ShardVaultStorage.layout().yieldFeeBP = feeBP;
        emit SetYieldFee(feeBP);
    }

    /**
     * @notice grants or revokes the 'authorized' state to an account
     * @param account address of account to grant/revoke 'authorized'
     * @param isAuthorized value of 'authorized' state
     */
    function _setAuthorized(address account, bool isAuthorized) internal {
        ShardVaultStorage.layout().authorized[account] = isAuthorized;
        emit SetAuthorized(account, isAuthorized);
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
        _enforceIsPUSDVault();
        //pUSD is in position 0 in the curve meta pool
        pUSD = _unstake(
            amount,
            minPUSD,
            poolInfoIndex,
            PUSD_CITADEL,
            CURVE_PUSD_POOL,
            0
        );

        emit UnstakePUSD(pUSD);
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
        _enforceIsPETHVault();

        //pETH is in position 1 in the curve meta pool
        pETH = _unstake(
            amount,
            minPETH,
            poolInfoIndex,
            PETH_CITADEL,
            CURVE_PETH_POOL,
            1
        );

        emit UnstakePETH(pETH);
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
     * @param punkId punkId pertinent to position
     * @param minPETH minimum pETH to receive from curveLP after unstake
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param minETH minimum amount of ETH to receive from curveLP after exchange
     */
    function _closePunkPositionPETH(
        uint256 punkId,
        uint256 minPETH,
        uint256 poolInfoIndex,
        uint256 minETH
    ) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        _enforceIsPETHVault();

        uint256 peth = _closePunkPosition(
            punkId,
            minPETH,
            poolInfoIndex,
            l.jpegdVault,
            PETH,
            PETH_CITADEL,
            CURVE_PETH_POOL,
            int128(1)
        );

        IERC20(PETH).approve(CURVE_PETH_POOL, peth);
        uint256 eth = ICurveMetaPool(CURVE_PETH_POOL).exchange(
            int128(1),
            int128(0),
            peth,
            minETH
        );

        l.cumulativeETHPerShard += eth / _totalSupply();
        emit ClosePunkPositionPETH(punkId, eth);
    }

    /**
     * @notice liquidates all staked tokens in order to pay back loan, retrieves collateralized punk
     * @param punkId punkId pertinent to position
     * @param minTokenAmount minimum token (pETH/pUSD) to receive from curveLP
     * @param poolInfoIndex index of pool in lpFarming pool array
     * @param jpegdVault address of jpeg'd NFT Vault
     * @param token address of PETH or PUSD
     * @param citadel address of jpeg citadel
     * @param pool address of Curve pool
     * @param curveID curve pool index of token to receive
     * @return surplus amount of PETH/PUSD left over after paying outstanding debt
     */
    function _closePunkPosition(
        uint256 punkId,
        uint256 minTokenAmount,
        uint256 poolInfoIndex,
        address jpegdVault,
        address token,
        address citadel,
        address pool,
        int128 curveID
    ) internal returns (uint256 surplus) {
        uint256 debt = _totalDebt(jpegdVault, punkId);

        uint256 tokenAmount = _unstake(
            _queryAutoCompForPETH(debt),
            minTokenAmount,
            poolInfoIndex,
            citadel,
            pool,
            curveID
        );

        IERC20(token).approve(jpegdVault, debt);
        INFTVault(jpegdVault).repay(punkId, debt);
        INFTVault(jpegdVault).closePosition(punkId);

        surplus = tokenAmount - debt;
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
        address marketPlaceHelper = _marketplaceHelper();
        ICryptoPunkMarket(PUNKS).transferPunk(marketPlaceHelper, punkId);
        IMarketPlaceHelper(marketPlaceHelper).listAsset(calls);
        emit ListPunk(punkId);
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
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        _enforceIsPUSDVault();
        address jpegdVault = l.jpegdVault;

        uint256 autoComp = _queryAutoCompForPUSD(amount);
        paidDebt = _unstakePUSD(autoComp, minPUSD, poolInfoIndex);

        if (amount > paidDebt) {
            revert ShardVault__DownPaymentInsufficient();
        }

        IERC20(PUSD).approve(jpegdVault, paidDebt);
        INFTVault(jpegdVault).repay(punkId, paidDebt);
        emit RepayLoanPUSD(paidDebt);
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
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        _enforceIsPETHVault();
        address jpegdVault = l.jpegdVault;

        uint256 autoComp = _queryAutoCompForPETH(amount);
        paidDebt = _unstakePETH(autoComp, minPETH, poolInfoIndex);

        if (amount > paidDebt) {
            revert ShardVault__DownPaymentInsufficient();
        }

        IERC20(PETH).approve(jpegdVault, paidDebt);
        INFTVault(jpegdVault).repay(punkId, paidDebt);
        emit RepayLoanPETH(paidDebt);
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
    function _queryAutoCompForPUSD(
        uint256 pUSD
    ) internal view returns (uint256 autoComp) {
        //note: does not account for fees, not meant for precise calculations.
        //      this is alright because it acts as a small 'buffer' to the amount
        //      necessary for the downpayment to impact the debt as intended
        uint256 curveLP = ICurveMetaPool(CURVE_PUSD_POOL).calc_token_amount(
            [pUSD, 0],
            false
        );

        //note: accounts for fees;
        uint256 curveLPAccountingFee = (curveLP * CURVE_BASIS) /
            (CURVE_BASIS - CURVE_FEE);

        autoComp =
            (curveLPAccountingFee * 10 ** IVault(PUSD_CITADEL).decimals()) /
            IVault(PUSD_CITADEL).exchangeRate();
    }

    /**
     * @notice returns amount of AutoComp LP shares needed to be burnt during unstaking
     * to result in a given amount of pETH
     * @param pETH desired pETH amount
     * @return autoComp required AutoComp LP shares
     */
    function _queryAutoCompForPETH(
        uint256 pETH
    ) internal view returns (uint256 autoComp) {
        //note: does not account for fees, not meant for precise calculations.
        //      this is alright because it acts as a small 'buffer' to the amount
        //      necessary for the downpayment to impact the debt as intended
        uint256 curveLP = ICurveMetaPool(CURVE_PETH_POOL).calc_token_amount(
            [0, pETH],
            false
        );

        // //note: accounts for fees;
        uint256 curveLPAccountingFee = (curveLP * CURVE_BASIS) /
            (CURVE_BASIS - CURVE_FEE);

        autoComp =
            (curveLPAccountingFee * 10 ** IVault(PETH_CITADEL).decimals()) /
            IVault(PETH_CITADEL).exchangeRate();
    }

    /**
     * @notice accepts a punk bid and withdraws any proceeds generated from punk sales
     * @dev called from marketPlaceHelper contract to transfer ETH proceeds from punk sale
     * @param calls encoded calls required to accept bid on an asset
     * @param punkId id of punk to accept bid on
     */
    function _acceptPunkBid(
        IMarketPlaceHelper.EncodedCall[] memory calls,
        uint256 punkId
    ) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();
        IMarketPlaceHelper(l.marketPlaceHelper).acceptAssetBid(calls);
        l.ownedTokenIds.remove(punkId);
        emit AccetPunkBid(punkId);
    }

    /**
     * @notice receives proceeds from punks sold, and removes any required punkIds from ownedTokenIds
     * @param calls encoded calls required to withdraw proceeds of sold punks
     * @param punkIds ids of punk to remove
     */
    function _receivePunkProceeds(
        IMarketPlaceHelper.EncodedCall[] memory calls,
        uint256[] memory punkIds
    ) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 proceeds = IMarketPlaceHelper(l.marketPlaceHelper)
            .forwardSaleProceeds(calls);
        uint256 saleFee = (proceeds * l.saleFeeBP) / BASIS_POINTS;
        l.accruedFees += saleFee;
        l.cumulativeETHPerShard += (proceeds - saleFee) / _totalSupply();

        uint256 idLength = punkIds.length;
        if (idLength > 0) {
            unchecked {
                for (uint256 i; i < idLength; i++) {
                    l.ownedTokenIds.remove(punkIds[i]);
                }
            }
        }

        emit ReceivePunkProceeds(proceeds);
    }

    /**
     * @notice returns total debt owed to jpeg'd vault for a given token
     * @param jpegdVault address of jpeg'd NFT vault
     * @param tokenId id of token position pertains to
     * @return debt total debt owed
     */
    function _totalDebt(
        address jpegdVault,
        uint256 tokenId
    ) internal view returns (uint256 debt) {
        debt =
            INFTVault(jpegdVault).getDebtInterest(tokenId) +
            INFTVault(jpegdVault).positions(tokenId).debtPrincipal;
    }

    /**
     * @notice sets the maxSupply of shards
     * @param maxSupply the maxSupply of shards
     */
    function _setMaxSupply(uint64 maxSupply) internal {
        if (maxSupply < _totalSupply()) {
            revert ShardVault__MaxSupplyTooSmall();
        }
        ShardVaultStorage.layout().maxSupply = maxSupply;

        emit SetMaxSupply(maxSupply);
    }

    /**
     * @notice provides yield in the form of ETH and JPEG tokens, by unstaking part of the pETH position to convert to yield,
     * and claiming pending rewards in LP_FARM to receive JPEG and increasing EPS/JPS respectively
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
        _enforceIsPETHVault();
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

        uint256 totalSupply = _totalSupply();
        l.cumulativeETHPerShard += providedETH / totalSupply;
        l.cumulativeJPEGPerShard += providedJPEG / totalSupply;

        emit ProvideYieldPETH(providedETH, providedJPEG);
    }

    /**
     * @notice sends excess ETH left over after vault has invested, to the msg.sender
     * @param shardIds array of shard IDs to claim with
     */
    function _claimExcessETH(uint256[] memory shardIds) internal {
        _claimExcessETH(msg.sender, shardIds);
    }

    /**
     * @notice sends excess ETH left over after vault has invested
     * @param account address making the claim
     * @param shardIds array of shard IDs to claim with
     */
    function _claimExcessETH(
        address account,
        uint256[] memory shardIds
    ) private {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 tokens = shardIds.length;

        _enforceNotYieldClaimingAndInvested();
        _enforceSufficientBalance(account, tokens);

        uint256 cumulativeETHPerShard = l.cumulativeETHPerShard;
        uint256 totalETH;
        uint256 claimedETHPerShard;

        unchecked {
            for (uint256 i; i < tokens; ++i) {
                uint256 shardId = shardIds[i];
                _enforceShardOwnership(account, shardId);

                claimedETHPerShard =
                    cumulativeETHPerShard -
                    l.claimedETHPerShard[shardId];
                totalETH += claimedETHPerShard;
                l.claimedETHPerShard[shardId] += claimedETHPerShard;
            }
        }

        payable(account).sendValue(totalETH);
    }

    /**
     * @notice sends yield in the form of ETH + JPEG tokens to msg.sender
     * @param shardIds array of shard IDs to claim with
     * @param tokenIdDOI Dawn of INSRT token ID used to apply yieldFeeBP discount
     */
    function _claimYield(
        uint256[] memory shardIds,
        uint256 tokenIdDOI
    ) internal {
        _claimYield(msg.sender, shardIds, tokenIdDOI);
    }

    /**
     * @notice sends yield in the form of ETH + JPEG tokens to account
     * @param account address making the yield claim
     * @param shardIds array of shard IDs to claim with
     * @param tokenIdDOI Dawn of INSRT token ID used to apply yieldFeeBP discount
     */
    function _claimYield(
        address account,
        uint256[] memory shardIds,
        uint256 tokenIdDOI
    ) private {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256 tokens = shardIds.length;

        _enforceYieldClaiming();
        _enforceSufficientBalance(account, tokens);

        //parameters for ETH claiming
        uint256 cumulativeETHPerShard = l.cumulativeETHPerShard;
        uint256 totalETH;
        uint256 claimedETHPerShard;
        //parameters for JPEG claiming
        uint256 cumulativeJPEGPerShard = l.cumulativeJPEGPerShard;
        uint256 totalJPEG;
        uint256 claimedJPEGPerShard;

        unchecked {
            for (uint256 i; i < tokens; ++i) {
                uint256 shardId = shardIds[i];
                _enforceShardOwnership(account, shardId);

                //account for claimable ETH
                claimedETHPerShard =
                    cumulativeETHPerShard -
                    l.claimedETHPerShard[shardId];
                totalETH += claimedETHPerShard;
                l.claimedETHPerShard[shardId] += claimedETHPerShard;

                //account for claimable JPEG
                claimedJPEGPerShard =
                    cumulativeJPEGPerShard -
                    l.claimedJPEGPerShard[shardId];
                totalJPEG += claimedJPEGPerShard;
                l.claimedJPEGPerShard[shardId] += claimedJPEGPerShard;
            }
        }

        uint16 yieldFeeBP = _discountYieldFeeBP(
            account,
            tokenIdDOI,
            l.yieldFeeBP
        );

        //apply fees
        uint256 ETHfee = (totalETH * yieldFeeBP) / BASIS_POINTS;
        l.accruedFees += ETHfee;

        uint256 jpegFee = (totalJPEG * yieldFeeBP) / BASIS_POINTS;
        l.accruedJPEG += jpegFee;

        //transfer yield
        IERC20(JPEG).transfer(account, totalJPEG - jpegFee);
        payable(account).sendValue(totalETH - ETHfee);
    }

    /**
     * @notice claim yield/excess ETH upon shard transfer
     * @dev only SHARD_COLLECTION proxy may call
     * @param from address transferring
     * @param to address receiving
     * @param shardId id of shard being transferred
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 shardId
    ) internal virtual override {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        uint256[] memory shardIds;
        uint256[] memory temp = new uint256[](1);
        temp[0] = shardId;
        shardIds = temp;

        if (from != address(0)) {
            if (l.isYieldClaiming) {
                _claimYield(from, shardIds, type(uint256).max);
            }

            if (!l.isYieldClaiming && l.isInvested) {
                _claimExcessETH(from, shardIds);
            }
        }
    }

    /**
     * @notice sets the whitelistEndsAt timestamp
     * @param whitelistEndsAt timestamp of whitelist end
     */
    function _setWhitelistEndsAt(uint48 whitelistEndsAt) internal {
        ShardVaultStorage.layout().whitelistEndsAt = whitelistEndsAt;
        emit SetWhitelistEndsAt(whitelistEndsAt);
    }

    /**
     * @notice sets the maximum amount of shard to be minted during whitelist
     * @param reservedSupply whitelist shard amount
     */
    function _setReservedSupply(uint64 reservedSupply) internal {
        ShardVaultStorage.Layout storage l = ShardVaultStorage.layout();

        if (l.maxSupply < reservedSupply) {
            revert ShardVault__ExceededMaxSupply();
        }

        l.reservedSupply = reservedSupply;
        emit SetReservedSupply(reservedSupply);
    }

    /**
     * @notice sets the isEnabled flag
     * @param isEnabled boolean value
     */
    function _setIsEnabled(bool isEnabled) internal {
        ShardVaultStorage.layout().isEnabled = isEnabled;
        emit SetIsEnabled(isEnabled);
    }

    /**
     * @notice return the maximum shards a user is allowed to mint; theoretically a user may acquire more than this amount via transfers,
     * but once this amount is exceeded said user may not deposit more
     * @param maxMintBalance new maxMintBalance value
     */
    function _setMaxMintBalance(uint64 maxMintBalance) internal {
        ShardVaultStorage.layout().maxMintBalance = maxMintBalance;
        emit SetMaxMintBalance(maxMintBalance);
    }

    /**
     * @notice returns sum of total fees (sale, yield, acquisition) accrued over the entire lifetime of the vault; accounts for fee withdrawals
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
     * @notice return the maximum shards a user is allowed to mint; theoretically a user may acquire more than this amount via transfers,
     * but once this amount is exceeded said user may not deposit more
     * @return maxBalance maxMintBalance value
     */
    function _maxMintBalance() internal view returns (uint64 maxBalance) {
        maxBalance = ShardVaultStorage.layout().maxMintBalance;
    }

    /**
     * @notice returns vault-wide amount of shards that can still be minted
     * @return supply amount of shards which can still be minted
     */
    function _remainingSupply() internal view returns (uint256 supply) {
        supply = ShardVaultStorage.layout().maxSupply - _totalSupply();
    }

    /**
     * @notice returns the authorized status of an account
     * @param account address to check status of
     * @return isAuthorized authorized status of account
     */
    function _isAuthorized(
        address account
    ) internal view returns (bool isAuthorized) {
        isAuthorized = ShardVaultStorage.layout().authorized[account];
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
        return ShardVaultStorage.layout().marketPlaceHelper;
    }

    /**
     * @notice returns the JPEG claimed by a given shard
     * @param shardId id of shard to check
     * @return claimedJPEGPerShard claimed JPEG for given shard
     */
    function _claimedJPEGPerShard(
        uint256 shardId
    ) internal view returns (uint256 claimedJPEGPerShard) {
        claimedJPEGPerShard = ShardVaultStorage.layout().claimedJPEGPerShard[
            shardId
        ];
    }

    /**
     * @notice returns the ETH claimed by a given shard
     * @param shardId id of shard to check
     * @return claimedETHPerShard claimed ETH for given shard
     */
    function _claimedETHPerShard(
        uint256 shardId
    ) internal view returns (uint256 claimedETHPerShard) {
        claimedETHPerShard = ShardVaultStorage.layout().claimedETHPerShard[
            shardId
        ];
    }

    /**
     * @notice returns the cumulative JPEG per shard value
     * @return cumulativeJPEGPerShard cumulative JPEG per shard value
     */
    function _cumulativeJPEGPerShard()
        internal
        view
        returns (uint256 cumulativeJPEGPerShard)
    {
        cumulativeJPEGPerShard = ShardVaultStorage
            .layout()
            .cumulativeJPEGPerShard;
    }

    /**
     * @notice returns the cumulative ETH per shard value
     * @return cumulativeETHPerShard cumulative ETH per shard value
     */
    function _cumulativeETHPerShard()
        internal
        view
        returns (uint256 cumulativeETHPerShard)
    {
        cumulativeETHPerShard = ShardVaultStorage
            .layout()
            .cumulativeETHPerShard;
    }

    /**
     * @notice returns the yield claiming status of the vault
     * @return isYieldClaiming the yield claiming status of the vault
     */
    function _isYieldClaiming() internal view returns (bool isYieldClaiming) {
        isYieldClaiming = ShardVaultStorage.layout().isYieldClaiming;
    }

    /**
     * @notice returns timestamp of whitelist end
     * @return whitelistEndsAt timestamp of whitelist end
     */
    function _whitelistEndsAt() internal view returns (uint48 whitelistEndsAt) {
        whitelistEndsAt = ShardVaultStorage.layout().whitelistEndsAt;
    }

    /**
     * @notice returns treasury address
     * @return treasury address of treasury
     */
    function _treasury() internal view returns (address treasury) {
        treasury = TREASURY;
    }

    /**
     * @notice sets a new baseURI for ERC721Metadata
     * @param baseURI the new baseURI
     */
    function _setBaseURI(string memory baseURI) internal {
        ERC721MetadataStorage.layout().baseURI = baseURI;
        emit SetBaseURI(baseURI);
    }

    /**
     * @notice sets the new value of ltvBufferBP
     * @param ltvBufferBP new value of ltvBufferBP
     */
    function _setLtvBufferBP(uint16 ltvBufferBP) internal {
        _enforceBasis(ltvBufferBP);
        ShardVaultStorage.layout().ltvBufferBP = ltvBufferBP;
        emit SetLtvBufferBP(ltvBufferBP);
    }

    /**
     * @notice sets the new value of ltvDeviationBP
     * @param ltvDeviationBP new value of ltvDeviationBP
     */
    function _setLtvDeviationBP(uint16 ltvDeviationBP) internal {
        _enforceBasis(ltvDeviationBP);
        ShardVaultStorage.layout().ltvDeviationBP = ltvDeviationBP;
        emit SetLtvDeviationBP(ltvDeviationBP);
    }

    /**
     * @notice check to ensure account owns a given shardId corresponding to a shard
     * @param account address to check
     * @param shardId shardId to check
     */
    function _enforceShardOwnership(
        address account,
        uint256 shardId
    ) internal view {
        if (account != _ownerOf(shardId)) {
            revert ShardVault__NotShardOwner();
        }
    }

    /**
     * @notice check to ensure an account has a balance larger than amount
     * @param account address to check
     * @param amount amount to check
     */
    function _enforceSufficientBalance(
        address account,
        uint256 amount
    ) internal view {
        if (amount > _balanceOf(account)) {
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
        if (l.isYieldClaiming || !l.isInvested) {
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

    /**
     * @notice stakes a jpeg card
     * @param tokenId id of card in card collection
     */
    function _stakeCard(uint256 tokenId) internal {
        IERC721(JPEG_CARDS).approve(JPEG_CARDS_CIG_STAKING, tokenId);
        IJpegCardsCigStaking(JPEG_CARDS_CIG_STAKING).deposit(tokenId);
    }

    /**
     * @notice unstakes a jpeg card
     * @param tokenId id of card in card collection
     */
    function _unstakeCard(uint256 tokenId) internal {
        IJpegCardsCigStaking(JPEG_CARDS_CIG_STAKING).withdraw(tokenId);
    }

    /**
     * @notice transfers a jpeg card to an address
     * @param tokenId id of card in card collection
     * @param to address to transfer to
     */
    function _transferCard(uint256 tokenId, address to) internal {
        IERC721(JPEG_CARDS).transferFrom(address(this), to, tokenId);
    }

    /**
     * @notice enforces that the type of the vault matches the type of the call
     */
    function _enforceIsPUSDVault() internal view {
        if (ShardVaultStorage.layout().isPUSDVault == false)
            revert ShardVault__CallTypeProhibited();
    }

    /**
     * @notice enforces that the type of the vault matches the type of the call
     */
    function _enforceIsPETHVault() internal view {
        if (ShardVaultStorage.layout().isPUSDVault == true)
            revert ShardVault__CallTypeProhibited();
    }

    /**
     * @notice returns the isEnabled status of the vault
     * @return isEnabled status of isEnabled of the vault
     */
    function _isEnabled() internal view returns (bool isEnabled) {
        isEnabled = ShardVaultStorage.layout().isEnabled;
    }

    /**
     * @notice applies a discount on yield fee
     * @param account address to check for discount
     * @param tokenId Dawn of Insrt token Id
     * @param rawYieldFeeBP the undiscounted yield fee in basis points
     */
    function _discountYieldFeeBP(
        address account,
        uint256 tokenId,
        uint16 rawYieldFeeBP
    ) internal view returns (uint16 yieldFeeBP) {
        if (tokenId == type(uint256).max) {
            yieldFeeBP = rawYieldFeeBP;
        } else {
            if (account != IERC721(DAWN_OF_INSRT).ownerOf(tokenId)) {
                revert ShardVault__NotDawnOfInsrtTokenOwner();
            }
            uint8 tier = IDawnOfInsrt(DAWN_OF_INSRT).tokenTier(tokenId);

            uint256 discount;
            if (tier == 0) {
                discount = TIER0_FEE_COEFFICIENT;
            } else if (tier == 1) {
                discount = TIER1_FEE_COEFFICIENT;
            } else if (tier == 2) {
                discount = TIER2_FEE_COEFFICIENT;
            } else if (tier == 3) {
                discount = TIER3_FEE_COEFFICIENT;
            } else {
                discount = TIER4_FEE_COEFFICIENT;
            }

            yieldFeeBP = uint16((rawYieldFeeBP * discount) / BASIS_POINTS);
        }
    }
}

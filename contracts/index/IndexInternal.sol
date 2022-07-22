// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';
import { ERC20BaseInternal } from '@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC4626BaseInternal } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseInternal.sol';
import { UintUtils } from '@solidstate/contracts/utils/UintUtils.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';
import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';

import { IIndexInternal } from './IIndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IBalancerHelpers } from '../balancer/IBalancerHelpers.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IAsset, IVault } from '../balancer/IVault.sol';

/**
 * @title Infra Index internal functions
 * @dev inherited by all Index implementation contracts
 */
abstract contract IndexInternal is
    IIndexInternal,
    ERC20MetadataInternal,
    OwnableInternal,
    ERC4626BaseInternal
{
    using UintUtils for uint256;
    using ABDKMath64x64 for int128;
    using SafeERC20 for IERC20;

    address internal immutable BALANCER_VAULT;
    address internal immutable BALANCER_HELPERS;
    address internal immutable SWAPPER;

    int128 internal immutable EXIT_FEE_FACTOR_64x64;
    int128 internal immutable STREAMING_FEE_FACTOR_PER_SECOND_64x64;
    int128 internal constant ONE_64x64 = 0x10000000000000000;

    uint256 internal constant BASIS = 10000;

    constructor(
        address balancerVault,
        address balancerHelpers,
        address swapper,
        uint256 exitFeeBP,
        uint256 streamingFeeBP
    ) {
        BALANCER_VAULT = balancerVault;
        BALANCER_HELPERS = balancerHelpers;
        SWAPPER = swapper;

        EXIT_FEE_FACTOR_64x64 = ABDKMath64x64.divu(BASIS - exitFeeBP, BASIS);

        STREAMING_FEE_FACTOR_PER_SECOND_64x64 = ONE_64x64.sub(
            ABDKMath64x64.divu(streamingFeeBP, BASIS * 365.25 days)
        );
    }

    modifier onlyProtocolOwner() {
        require(msg.sender == _protocolOwner(), 'Not protocol owner');
        _;
    }

    /**
     * @notice returns the protocol owner
     * @return address of the protocol owner
     */
    function _protocolOwner() internal view returns (address) {
        return IERC173(_owner()).owner();
    }

    /**
     * @notice return total fees accrued
     * @return uint256 total fees accrued
     */
    function _feesAccrued() internal view returns (uint256) {
        return IndexStorage.layout().feesAccrued;
    }

    /**
     * @notice get the ID of the underlying Balancer pool
     * @return poolId
     */
    function _poolId() internal view virtual returns (bytes32) {
        return IndexStorage.layout().poolId;
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _name() internal view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'Insrt Finance InfraIndex #',
                    IndexStorage.layout().id.toString()
                )
            );
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _symbol() internal view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked('IFII-', IndexStorage.layout().id.toString())
            );
    }

    /**
     * @inheritdoc ERC20MetadataInternal
     */
    function _decimals() internal pure virtual override returns (uint8) {
        return 18;
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     */
    function _totalAssets() internal view override returns (uint256) {
        // return BPT balance, which is equal to total Index token supply
        return _totalSupply();
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     * @dev assets and shares are pegged 1:1, so this override is made for gas savings
     */
    function _convertToAssets(uint256 shareAmount)
        internal
        view
        virtual
        override
        returns (uint256 assetAmount)
    {
        assetAmount = shareAmount;
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     * @dev assets and shares are pegged 1:1, so this override is made for gas savings
     */
    function _convertToShares(uint256 assetAmount)
        internal
        view
        virtual
        override
        returns (uint256 shareAmount)
    {
        shareAmount = assetAmount;
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     * @dev assets and shares are pegged 1:1, so this function acts as an alias of _previewDeposit
     */
    function _previewMint(uint256 shareAmount)
        internal
        view
        virtual
        override
        returns (uint256 assetAmount)
    {
        assetAmount = _previewDeposit(shareAmount);
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     * @dev assets and shares are pegged 1:1, so this function acts as an alias of _previewRedeem
     */
    function _previewWithdraw(uint256 assetAmount)
        internal
        view
        virtual
        override
        returns (uint256 shareAmount)
    {
        IndexStorage.Layout storage l = IndexStorage.layout();

        shareAmount = STREAMING_FEE_FACTOR_PER_SECOND_64x64
            .pow(block.timestamp - l.feeUpdatedAt[msg.sender])
            .mul(EXIT_FEE_FACTOR_64x64)
            .inv()
            .mulu(assetAmount);
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     * @dev apply exit fee and streaming fee to amount out
     */
    function _previewRedeem(uint256 shareAmount)
        internal
        view
        virtual
        override
        returns (uint256 assetAmount)
    {
        IndexStorage.Layout storage l = IndexStorage.layout();

        assetAmount = _applyExitFee(
            _applyStreamingFee(shareAmount, l.feeUpdatedAt[msg.sender])
        );
    }

    /**
     * @notice calculate exit fee for given principal amount
     * @param principal the token amount to which fee is applied
     * @return amountOut amount after fee
     */
    function _applyExitFee(uint256 principal)
        internal
        view
        returns (uint256 amountOut)
    {
        amountOut = EXIT_FEE_FACTOR_64x64.mulu(principal);
    }

    /**
     * @notice calculate streaming fee for a given principal amount and duration of accrual
     * @dev uses exponential decay formula to calculate streaming fee over a given duration
     * @param principal the token amount to which fee is applied
     * @param timestamp timestamp of beginning of fee accrual period
     * @return amountOut amount after fee
     */
    function _applyStreamingFee(uint256 principal, uint256 timestamp)
        internal
        view
        returns (uint256 amountOut)
    {
        amountOut = STREAMING_FEE_FACTOR_PER_SECOND_64x64
            .pow(block.timestamp - timestamp)
            .mulu(principal);
    }

    /*
     * @notice calculate and collect exit fee
     * @notice calculate and collect accrued streaming fees
     * @param account address which owes streaming fees
     * @param amount quantity of share tokens to subject to fee calculation
     */
    function _collectExitFee(address account, uint256 amount) internal {
        if (amount == 0) return;

        uint256 fee = amount - _applyExitFee(amount);

        IndexStorage.layout().feesAccrued += fee;

        // exit fees are only applied when calling withdraw and redeem functions
        // these functions execute burn internally, so do not burn here

        emit ExitFeePaid(account, fee);
    }

    /**
     * @notice calculate and collect accrued streaming fees
     * @param account address which owes streaming fees
     * @param amount quantity of share tokens to subject to fee calculation
     * @param checkpoint whether to update fee collection timestamp (should be true if processing account's full balance)
     * @param burn whether to burn tokens held by account corresponding to fee amount (should be true except on vault exit)
     */
    function _collectStreamingFee(
        address account,
        uint256 amount,
        bool checkpoint,
        bool burn
    ) internal returns (uint256 amountOut) {
        IndexStorage.Layout storage l = IndexStorage.layout();

        if (amount == 0) return 0;

        uint256 feeUpdatedAt = l.feeUpdatedAt[account];

        if (checkpoint) {
            l.feeUpdatedAt[account] = block.timestamp;
        }

        amountOut = _applyStreamingFee(amount, feeUpdatedAt);
        uint256 fee = amount - amountOut;

        if (account == address(0)) {
            l.feesAccrued += fee;
        }

        if (burn) {
            _burn(account, fee);
        }

        emit StreamingFeePaid(account, fee);
    }

    /**
     * @notice construct Balancer join request and exchange underlying pool tokens for BPT
     * @param amounts token quantities to deposit, in asset-sorted order
     * @param userData encoded join parameters
     */
    function _joinPool(uint256[] memory amounts, bytes memory userData)
        internal
    {
        IndexStorage.Layout storage l = IndexStorage.layout();

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest(
            l.tokens,
            amounts,
            userData,
            false
        );

        IVault(BALANCER_VAULT).joinPool(
            _poolId(),
            address(this),
            address(this),
            request
        );
    }

    /**
     * @notice construct Balancer exit request, exchange BPT for underlying pool token(s)
     * @param minAmountsOut minimum amounts to be returned by Balancer
     * @param userData encoded exit parameters
     * @param receiver recipient of withdrawn pool tokens
     * @return poolTokenAmounts quantities of underlying pool tokens yielded
     */
    function _exitPool(
        uint256[] memory minAmountsOut,
        bytes memory userData,
        address receiver
    ) internal returns (uint256[] memory poolTokenAmounts) {
        IndexStorage.Layout storage l = IndexStorage.layout();

        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(
            l.tokens,
            minAmountsOut,
            userData,
            false
        );

        (, poolTokenAmounts) = IBalancerHelpers(BALANCER_HELPERS).queryExit(
            l.poolId,
            address(this),
            payable(receiver),
            request
        );

        IVault(BALANCER_VAULT).exitPool(
            l.poolId,
            address(this),
            payable(receiver),
            request
        );
    }

    /**
     * @inheritdoc ERC20BaseInternal
     * @dev collects accrued streaming fees from holder and receiver, and reduces amount transferred accordingly
     */
    function _transfer(
        address holder,
        address receiver,
        uint256 amount
    ) internal virtual override returns (bool) {
        _collectStreamingFee(receiver, _balanceOf(receiver), true, true);

        return
            super._transfer(
                holder,
                receiver,
                _collectStreamingFee(holder, amount, false, true)
            );
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     * @dev apply exit fee and streaming to shareAmount
     */
    function _beforeWithdraw(
        address owner,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal virtual override {
        super._beforeWithdraw(owner, assetAmount, shareAmount);

        _collectStreamingFee(address(0), _totalSupply(), true, false);
        _collectExitFee(
            owner,
            _collectStreamingFee(owner, shareAmount, false, false)
        );
    }

    /**
     * @inheritdoc ERC4626BaseInternal
     * @dev collects accrued streaming fees from receiver of deposit
     */
    function _afterDeposit(
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal virtual override {
        super._afterDeposit(receiver, assetAmount, shareAmount);

        unchecked {
            // apply fee to previous balance, ignoring newly minted shareAmount
            _collectStreamingFee(
                address(0),
                _totalSupply() - shareAmount,
                true,
                false
            );
            _collectStreamingFee(
                receiver,
                _balanceOf(receiver) - shareAmount,
                true,
                true
            );
        }
    }
}

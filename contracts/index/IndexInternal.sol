// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';
import { ERC20BaseStorage } from '@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC4626BaseInternal } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseInternal.sol';
import { UintUtils } from '@solidstate/contracts/utils/UintUtils.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

import { ABDKMath64x64 } from 'abdk-libraries-solidity/ABDKMath64x64.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IBalancerHelpers } from '../balancer/IBalancerHelpers.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IAsset, IVault } from '../balancer/IVault.sol';

/**
 * @title Infra Index internal functions
 * @dev inherited by all Index implementation contracts
 */
abstract contract IndexInternal is
    ERC4626BaseInternal,
    ERC20MetadataInternal,
    OwnableInternal
{
    using UintUtils for uint256;
    using ABDKMath64x64 for int128;
    using SafeERC20 for IERC20;

    address internal immutable BALANCER_VAULT;
    address internal immutable BALANCER_HELPERS;
    address internal immutable SWAPPER;
    uint256 internal immutable EXIT_FEE_BP;
    uint256 internal constant FEE_BASIS = 1 ether;
    int128 internal immutable DECAY_FACTOR_64x64;
    int128 internal constant ONE_64x64 = 0x10000000000000000; //64x64 representation of 1

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
        EXIT_FEE_BP = exitFeeBP;

        DECAY_FACTOR_64x64 = ONE_64x64.sub(
            ABDKMath64x64.div(
                ABDKMath64x64.divu(streamingFeeBP, FEE_BASIS),
                ABDKMath64x64.fromUInt(uint256(365.25 days))
            )
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
     * @notice construct Balancer join request and exchange underlying pool tokens for BPT
     * @param amounts token quantities to deposit, in asset-sorted order
     * @param userData encoded join parameters
     */
    function _joinPool(uint256[] memory amounts, bytes memory userData)
        internal
    {
        IndexStorage.Layout storage l = IndexStorage.layout();

        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest(
            _tokensToAssets(l.tokens),
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
     * @param l index layout struct
     * @param minAmountsOut minimum amounts to be returned by Balancer
     * @param userData encoded exit parameters
     * @param receiver recipient of withdrawn pool tokens
     */
    function _exitPool(
        IndexStorage.Layout storage l,
        uint256[] memory minAmountsOut,
        bytes memory userData,
        address receiver
    ) internal returns (uint256[] memory poolTokenAmounts) {
        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(
            _tokensToAssets(l.tokens),
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
     * @notice function to calculate the totalFee and remainder when a fee is applied on an amount
     * @param fee the fee as 0-10**18 value representing a two decimal point percentage
     * @param amount the amount to apply the fee on
     * @return totalFee the actual value of the fee (not percent)
     * @return remainder the remaining amount after the fee has been subtracted from it
     */
    function _applyFee(uint256 fee, uint256 amount)
        internal
        view
        returns (uint256 totalFee, uint256 remainder)
    {
        if (msg.sender != _protocolOwner()) {
            totalFee = (fee * amount) / FEE_BASIS;
        }

        remainder = amount - totalFee;
    }

    //remove and save assets instead, saved on deployment?
    /**
     * @notice function to convert IERC20 to IAsset used in Balancer
     * @param tokens an array of IERC20-wrapped addresses
     * @return assets an array of IAsset-wrapped addresses
     */
    function _tokensToAssets(IERC20[] memory tokens)
        internal
        pure
        returns (IAsset[] memory assets)
    {
        assets = new IAsset[](tokens.length);
        for (uint256 i; i < tokens.length; i++) {
            assets[i] = (IAsset(address(tokens[i])));
        }
    }

    /**
     * @notice get the ID of the underlying Balancer pool
     * @return poolId
     */
    function _poolId() internal view virtual returns (bytes32) {
        return IndexStorage.layout().poolId;
    }

    /**
     * @notice get the exit fee in basis points
     * @return exitFee
     */
    function _exitFee() internal view virtual returns (uint256) {
        return EXIT_FEE_BP;
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
        shareAmount = _previewRedeem(assetAmount);
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
        (, uint256 assetAmountAfterExit) = _applyFee(EXIT_FEE_BP, shareAmount);

        IndexStorage.ReservedFeeData memory reservedFeeData = l.reservedFeeData[
            msg.sender
        ];

        assetAmount =
            assetAmountAfterExit -
            _calculateStreamingFee(
                assetAmountAfterExit,
                block.timestamp - reservedFeeData.updatedAt
            ) -
            reservedFeeData.amount;
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
        IndexStorage.Layout storage l = IndexStorage.layout();

        (uint256 exitFeeAmount, uint256 amountAfterExitFee) = _applyFee(
            EXIT_FEE_BP,
            shareAmount
        );

        IndexStorage.ReservedFeeData memory reservedFeeData = l.reservedFeeData[
            msg.sender
        ];

        uint256 totalFeeAmount = exitFeeAmount +
            _calculateStreamingFee(
                amountAfterExitFee,
                block.timestamp - reservedFeeData.updatedAt
            ) +
            reservedFeeData.amount;

        if (totalFeeAmount > 0) {
            _transfer(msg.sender, _protocolOwner(), totalFeeAmount);
        }
    }

    /**
     * @notice transfer tokens from holder to recipient
     * @dev accounts for streaming fee on token transfers
     * @param holder owner of tokens to be transferred
     * @param recipient beneficiary of transfer
     * @param amount quantity of tokens transferred
     * @return success status (always true; otherwise function should revert)
     */
    function _transfer(
        address holder,
        address recipient,
        uint256 amount
    ) internal virtual override returns (bool) {
        IndexStorage.Layout storage l = IndexStorage.layout();
        uint256 currTimestamp = block.timestamp;

        uint256 streamingFee;
        address protocolOwner = _protocolOwner();
        if (recipient == protocolOwner) {
            streamingFee = 0;
        } else {
            streamingFee =
                _calculateStreamingFee(
                    amount,
                    currTimestamp - l.reservedFeeData[holder].updatedAt
                ) +
                l.reservedFeeData[holder].amount;
            l.reservedFeeData[holder].amount = 0;
            uint256 recipientStreamingFeeAccumulation = _calculateStreamingFee(
                _balanceOf(recipient),
                currTimestamp - l.reservedFeeData[recipient].updatedAt
            );
            l
                .reservedFeeData[recipient]
                .amount += recipientStreamingFeeAccumulation;
            l.reservedFeeData[recipient].updatedAt = currTimestamp;
        }

        // TODO: emit StreamingFeePaid event

        super._transfer(holder, recipient, amount - streamingFee);
        super._transfer(holder, protocolOwner, streamingFee);
    }

    /**
     * @notice returns the streaming fee on an amount for a given duration
     * @dev uses exponential decay formula to calculate streaming fee over a given duration
     * @param amount amount to apply streaming fee to
     * @param duration duration in seconds to apply streaming fee over
     * @return totalFee the total fee calculated on the amount
     */
    function _calculateStreamingFee(uint256 amount, uint256 duration)
        internal
        view
        returns (uint256 totalFee)
    {
        totalFee = amount - (DECAY_FACTOR_64x64.pow(duration)).mulu(amount);
    }
}

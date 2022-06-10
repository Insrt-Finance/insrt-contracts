// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC173 } from '@solidstate/contracts/access/IERC173.sol';
import { OwnableInternal } from '@solidstate/contracts/access/ownable/OwnableInternal.sol';
import { OwnableStorage } from '@solidstate/contracts/access/ownable/OwnableStorage.sol';
import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC4626BaseInternal } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseInternal.sol';
import { UintUtils } from '@solidstate/contracts/utils/UintUtils.sol';

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

    address internal immutable BALANCER_VAULT;
    address internal immutable BALANCER_HELPERS;
    uint256 internal constant FEE_BASIS = 10000;

    constructor(address balancerVault, address balancerHelpers) {
        BALANCER_VAULT = balancerVault;
        BALANCER_HELPERS = balancerHelpers;
    }

    modifier onlyProtocolOwner() {
        require(
            msg.sender == IERC173(OwnableStorage.layout().owner).owner(),
            'Not protocol owner'
        );
        _;
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
    ) internal {
        IVault.ExitPoolRequest memory request = IVault.ExitPoolRequest(
            _tokensToAssets(l.tokens),
            minAmountsOut,
            userData,
            false
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
     * @param fee the fee as 0-10000 value representing a two decimal point percentage
     * @param amount the amount to apply the fee on
     * @return totalFee the actual value of the fee (not percent)
     * @return remainder the remaining amount after the fee has been subtracted from it
     */
    function _applyFee(uint16 fee, uint256 amount)
        internal
        view
        returns (uint256 totalFee, uint256 remainder)
    {
        if (msg.sender != _owner()) {
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
    function _exitFee() internal view virtual returns (uint16) {
        return IndexStorage.layout().exitFee;
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
        return IERC20(_asset()).balanceOf(address(this));
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
     * @dev apply exit fee to amount out
     */
    function _previewRedeem(uint256 shareAmount)
        internal
        view
        virtual
        override
        returns (uint256 assetAmount)
    {
        (, assetAmount) = _applyFee(
            IndexStorage.layout().exitFee,
            _convertToAssets(shareAmount)
        );
    }

    function _beforeWithdraw(
        address owner,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal virtual override {
        super._afterDeposit(owner, assetAmount, shareAmount);

        (uint256 feeAmount, ) = _applyFee(
            IndexStorage.layout().exitFee,
            _convertToAssets(shareAmount)
        );

        if (feeAmount > 0) {
            _transfer(owner, _owner(), feeAmount);
        }
    }
}

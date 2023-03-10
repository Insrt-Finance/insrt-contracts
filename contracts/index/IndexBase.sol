// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC20BaseInternal } from '@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol';
import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';
import { ERC4626BaseInternal } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseInternal.sol';
import { SolidStateERC4626 } from '@solidstate/contracts/token/ERC4626/SolidStateERC4626.sol';

import { IIndexBase } from './IIndexBase.sol';
import { IndexInternal } from './IndexInternal.sol';

/**
 * @title Infra Index base functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexBase is SolidStateERC4626, IndexInternal, IIndexBase {
    constructor(
        address balancerVault,
        address balancerHelpers,
        address swapper,
        uint256 exitFeeBP,
        uint256 streamingFeeBP
    )
        IndexInternal(
            balancerVault,
            balancerHelpers,
            swapper,
            exitFeeBP,
            streamingFeeBP
        )
    {}

    /**
     * @inheritdoc IndexInternal
     */
    function _name()
        internal
        view
        override(ERC20MetadataInternal, IndexInternal)
        returns (string memory)
    {
        return super._name();
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _symbol()
        internal
        view
        override(ERC20MetadataInternal, IndexInternal)
        returns (string memory)
    {
        return super._symbol();
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _decimals()
        internal
        pure
        override(ERC20MetadataInternal, IndexInternal)
        returns (uint8)
    {
        return super._decimals();
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _convertToAssets(
        uint256 shareAmount
    )
        internal
        view
        override(ERC4626BaseInternal, IndexInternal)
        returns (uint256 assetAmount)
    {
        assetAmount = super._convertToAssets(shareAmount);
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _convertToShares(
        uint256 assetAmount
    )
        internal
        view
        override(ERC4626BaseInternal, IndexInternal)
        returns (uint256 shareAmount)
    {
        shareAmount = super._convertToShares(assetAmount);
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _previewMint(
        uint256 shareAmount
    )
        internal
        view
        override(ERC4626BaseInternal, IndexInternal)
        returns (uint256 assetAmount)
    {
        assetAmount = super._previewMint(shareAmount);
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _previewWithdraw(
        uint256 assetAmount
    )
        internal
        view
        override(ERC4626BaseInternal, IndexInternal)
        returns (uint256 shareAmount)
    {
        shareAmount = super._previewWithdraw(assetAmount);
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _previewRedeem(
        uint256 shareAmount
    )
        internal
        view
        override(ERC4626BaseInternal, IndexInternal)
        returns (uint256 assetAmount)
    {
        assetAmount = super._previewRedeem(shareAmount);
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _beforeWithdraw(
        address owner,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal override(ERC4626BaseInternal, IndexInternal) {
        super._beforeWithdraw(owner, assetAmount, shareAmount);
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _transfer(
        address holder,
        address recipient,
        uint256 amount
    ) internal override(ERC20BaseInternal, IndexInternal) returns (bool) {
        return super._transfer(holder, recipient, amount);
    }

    /**
     * @inheritdoc IndexInternal
     */
    function _afterDeposit(
        address receiver,
        uint256 assetAmount,
        uint256 shareAmount
    ) internal override(ERC4626BaseInternal, IndexInternal) {
        super._afterDeposit(receiver, assetAmount, shareAmount);
    }
}

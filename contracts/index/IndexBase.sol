// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ERC4626 } from '@solidstate/contracts/token/ERC4626/ERC4626.sol';
import { ERC20MetadataInternal } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataInternal.sol';

import { IIndexBase } from './IIndexBase.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IVault, IAsset } from '../balancer/IVault.sol';
import { IBalancerHelpers } from '../balancer/IBalancerHelpers.sol';

/**
 * @title Infra Index base functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexBase is IIndexBase, ERC4626, IndexInternal {
    using IndexStorage for IndexStorage.Layout;

    constructor(address balancerVault, address balancerHelpers)
        IndexInternal(balancerVault, balancerHelpers)
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

    function userDepositAmounts(uint256[] memory amounts) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

        IVault.JoinPoolRequest memory request;

        JoinKind kind = JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
        bytes memory userData = abi.encodePacked(kind);

        request.assets = _tokensToAssets(l.tokens); //perhaps this function is needless if tokens are saved in storage as assets
        request.maxAmountsIn = amounts;
        request.userData = userData; //more userData needed?
        request.fromInternalBalance = false; // not coming from investment pools internal balance (Implications?)

        if (
            !IVault(BALANCER_VAULT).hasApprovedRelayer(
                msg.sender,
                address(this)
            )
        ) {
            //Note: https://github.com/balancer-labs/balancer-v2-monorepo/blob/9eb179da66c4f47c795b7b86479c3f13411c027d/pkg/vault/contracts/VaultAuthorization.sol#L116
            IVault(BALANCER_VAULT).setRelayerApproval(
                msg.sender,
                address(this),
                true
            );
        }

        //TODO: Is there a potential mismatch of results between queryJoin and joinPool?
        (uint256 bptOut, uint256[] memory amountsIn) = IBalancerHelpers(
            BALANCER_HELPERS
        ).queryJoin(l.poolId, address(this), address(this), request);

        //TODO: UserData implications
        //TODO: InternalBalance implications
        IVault(BALANCER_VAULT).joinPool(
            l.poolId,
            address(this),
            address(this),
            request
        );

        //Mint shares to joining user
        _mint(bptOut, msg.sender);
    }

    function userWithdraw(uint256 sharesOut) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

        //Maybe this should be accounted for somewhere? Automatically done by balanceOf bpt tokens
        (uint256 feeBpt, uint256 remainingSharesOut) = _applyFee(
            l.exitFee,
            sharesOut
        );

        IVault.ExitPoolRequest memory request;

        ExitKind kind = ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT;
        bytes memory userData = abi.encodePacked(kind);

        request.assets = _tokensToAssets(l.tokens);
        request.minAmountsOut = _convertToMinAmounts(remainingSharesOut);
        request.userData = userData;
        request.toInternalBalance = true; //implications?

        (uint256 bptIn, uint256[] memory amountsOut) = IBalancerHelpers(
            BALANCER_HELPERS
        ).queryExit(l.poolId, address(this), msg.sender, request);

        IVault(BALANCER_VAULT).exitPool(
            l.poolId,
            msg.sender,
            payable(address(this)),
            request
        );

        //User withdraw and burn shares for exiting user.
        _withdraw(sharesOut, msg.sender, msg.sender);
    }
}

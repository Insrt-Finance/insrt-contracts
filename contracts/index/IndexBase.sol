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

    function userDeposit(IVault.JoinPoolRequest memory request) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

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
        //TODO: Need to apply 'depositFee' to all registered tokens of investment pool?
        (uint256 bptOut, uint256[] memory amountsIn) = IBalancerHelpers(
            BALANCER_HELPERS
        ).queryJoin(l.poolId, address(this), address(this), request);

        uint256[] memory remainingTokens = _exactFees(
            l.tokens,
            l.depositFee,
            amountsIn
        );

        request.maxAmountsIn = remainingTokens;

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

    function userWithdraw(IVault.ExitPoolRequest memory request) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

        (uint256 bptIn, uint256[] memory amountsOut) = IBalancerHelpers(
            BALANCER_HELPERS
        ).queryExit(l.poolId, address(this), msg.sender, request);

        //TODO: Withdraw fee applied to all tokens in token array (amountsOut)?
        // Flow should perhaps be that this contract receives tokens, applies fee, transfers to msg.sender?
        IVault(BALANCER_VAULT).exitPool(
            l.poolId,
            msg.sender,
            payable(address(this)),
            request
        );

        //Mint shares to joining user
        _withdraw(bptIn, msg.sender, msg.sender);
    }
}

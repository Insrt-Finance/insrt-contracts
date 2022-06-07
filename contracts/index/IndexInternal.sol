// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

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
abstract contract IndexInternal is ERC4626BaseInternal, ERC20MetadataInternal {
    using UintUtils for uint256;

    address internal immutable BALANCER_VAULT;
    address internal immutable BALANCER_HELPERS;
    uint256 internal constant FEE_BASIS = 10000;

    constructor(address balancerVault, address balancerHelpers) {
        BALANCER_VAULT = balancerVault;
        BALANCER_HELPERS = balancerHelpers;
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
     * @notice function to call exitPool in Balancer vault, and withdraw/burn Insrt-index shares of user
     * @dev used for all exits as the functionality is common
     * @param sharesOut the amounts
     */
    function _performExitAndWithdraw(
        uint256 sharesOut,
        bytes32 poolId,
        IVault.ExitPoolRequest memory request
    ) internal {
        //TODO: confirm this does not drain vault
        IVault(BALANCER_VAULT).exitPool(
            poolId,
            address(this),
            payable(msg.sender),
            request
        );

        _withdraw(sharesOut, msg.sender, msg.sender);
    }

    /**
     * @notice function to construct the request needed for a user to withdraw shares of
     * the Insrt-Index, for a single token returned
     * @dev only works for ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT
     * @param l the index layout
     * @param amountsOut the amounts of each underlying token returned | perhaps not needed
     * @param bptAmountIn the BPT withdrawn from the pool
     * @param tokenId the tokenId of the token to be returned
     * @return request an ExitPoolRequest constructed for EXACT_BPT_IN_FOR_ONE_TOKEN_OUT
     */
    function _constructExitExactForSingleRequest(
        IndexStorage.Layout storage l,
        uint256[] memory amountsOut, //perhaps not needed
        uint256 bptAmountIn,
        uint256 tokenId
    ) internal view returns (IVault.ExitPoolRequest memory request) {
        IInvestmentPool.ExitKind kind = IInvestmentPool
            .ExitKind
            .BPT_IN_FOR_EXACT_TOKENS_OUT;

        (uint256 feeBpt, uint256 remainingBPTIn) = _applyFee(
            l.exitFee,
            bptAmountIn
        );

        bytes memory userData = abi.encode(kind, remainingBPTIn, tokenId);

        request = _constructExitRequest(l.tokens, amountsOut, userData);
    }

    /**
     * @notice function to construct the request needed for a user to redeem a certain amount of insrt-index shares
     * @dev only works for ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT
     * @param sharesOut the amount of insrt-index shares a user wants to redeem
     * @param minAmountsOut the minimum amount of each token the user is willing to accept
     * @return request an ExitPoolRequest constructed for EXACT_BPT_IN_FOR_TOKENS_OUT
     */
    function _constructExitExactForAllRequest(
        IndexStorage.Layout storage l,
        uint256 sharesOut,
        uint256[] memory minAmountsOut
    ) internal view returns (IVault.ExitPoolRequest memory request) {
        //Maybe this should be accounted for somewhere? Automatically done by balanceOf bpt tokens?
        (uint256 feeBpt, uint256 remainingSharesOut) = _applyFee(
            l.exitFee,
            sharesOut
        );
        IInvestmentPool.ExitKind kind = IInvestmentPool
            .ExitKind
            .EXACT_BPT_IN_FOR_TOKENS_OUT;
        //To perform an Exit of kind `EXACT_BPT_IN_FOR_TOKENS_OUT` the `userData` variable
        //must contain the encoded "kind" of exit, and the amount of BPT to "exit" from the
        //pool.
        bytes memory userData = abi.encode(kind, remainingSharesOut);

        request = _constructExitRequest(l.tokens, minAmountsOut, userData);
    }

    /**
     * @notice function to construct an arbitrary exit request
     * @dev fromInternalBalance always set to false as the assumption is made that the user will not
     * seek to send/keep tokens elsewhere in Balancer Vault.
     * Ref: https://github.com/balancer-labs/balancer-v2-monorepo/blob/a9b1e969a19c4f93c14cd19fba45aaa25b015d12/pkg/vault/contracts/interfaces/IVault.sol#L410
     * @param tokens the array of tokens to convert to assets
     * @param minAmountsOut the minimum amounts of tokens expected to be returned, for the BPT provided
     * @param userData the userData for the exit request
     * @return exitRequest the constructed ExitPoolRequest
     */
    function _constructExitRequest(
        IERC20[] memory tokens,
        uint256[] memory minAmountsOut,
        bytes memory userData
    ) internal pure returns (IVault.ExitPoolRequest memory exitRequest) {
        exitRequest.assets = _tokensToAssets(tokens);
        exitRequest.minAmountsOut = minAmountsOut;
        exitRequest.userData = userData;
        exitRequest.toInternalBalance = false;
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
        pure
        returns (uint256 totalFee, uint256 remainder)
    {
        totalFee = (fee * amount) / FEE_BASIS;
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
}

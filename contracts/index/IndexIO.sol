// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

import { IIndexIO } from './IIndexIO.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { IBalancerHelpers } from '../balancer/IBalancerHelpers.sol';
import { IInvestmentPool } from '../balancer/IInvestmentPool.sol';
import { IVault } from '../balancer/IVault.sol';

/**
 * @title Infra Index Input-Output functions
 * @dev deployed standalone and referenced by IndexProxy
 */
contract IndexIO is IndexInternal, IIndexIO {
    using IndexStorage for IndexStorage.Layout;
    using SafeERC20 for IERC20;

    constructor(address balancerVault, address balancerHelpers)
        IndexInternal(balancerVault, balancerHelpers)
    {}

    /**
     * @inheritdoc IIndexIO
     */
    function initialize(uint256[] memory amountsIn) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

        bytes memory userData = abi.encode(
            IInvestmentPool.JoinKind.INIT,
            amountsIn
        );

        IVault.JoinPoolRequest memory request = _constructJoinRequest(
            l.tokens,
            amountsIn,
            userData
        );

        IVault(BALANCER_VAULT).joinPool(
            l.poolId,
            address(this),
            address(this),
            request
        );

        // Mint an amount of shares to user for BPT received from Balancer Vault
        _mint(
            msg.sender,
            _previewDeposit(IERC20(_asset()).balanceOf(address(this)))
        );
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userDepositExactInForAnyOut(
        uint256[] memory amountsIn,
        uint256 minBPTAmountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

        bytes memory userData = abi.encode(
            IInvestmentPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            amountsIn,
            minBPTAmountOut
        );

        IVault.JoinPoolRequest memory request = _constructJoinRequest(
            l.tokens,
            amountsIn,
            userData
        );

        IERC20[] memory tokens = l.tokens;
        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength; ) {
            tokens[i].safeTransferFrom(msg.sender, address(this), amountsIn[i]);
            unchecked {
                ++i;
            }
        }

        uint256 oldSupply = _totalSupply();

        IVault(BALANCER_VAULT).joinPool(
            l.poolId,
            address(this),
            address(this),
            request
        );

        uint256 newSupply = IERC20(_asset()).balanceOf(address(this));

        _mint(msg.sender, newSupply - oldSupply);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userDepositSingleForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut,
        uint256 tokenIndex
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

        bytes memory userData = abi.encode(
            IInvestmentPool.JoinKind.TOKEN_IN_FOR_EXACT_BPT_OUT,
            bptAmountOut,
            tokenIndex
        );

        IVault.JoinPoolRequest memory request = _constructJoinRequest(
            l.tokens,
            amounts,
            userData
        );
        bytes32 poolId = l.poolId;

        IERC20 depositToken = l.tokens[tokenIndex];
        depositToken.safeTransferFrom(
            msg.sender,
            address(this),
            amounts[tokenIndex]
        ); //perhaps input may be a single value

        IVault(BALANCER_VAULT).joinPool(
            poolId,
            address(this),
            address(this),
            request
        );

        //Mint shares to joining user
        _mint(msg.sender, _previewDeposit(bptAmountOut));
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userDepositAllForExactOut(
        uint256[] memory amounts,
        uint256 bptAmountOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.JoinPoolRequest
            memory request = _constructJoinAllForExactRequest(
                l,
                amounts,
                bptAmountOut
            );

        _performJoinAndMint(bptAmountOut, l.poolId, request);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userWithdrawExactForAll(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.ExitPoolRequest
            memory request = _constructExitExactForAllRequest(
                l,
                sharesOut,
                minAmountsOut
            );

        _performExitAndWithdraw(sharesOut, l.poolId, request);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userWithdrawExactForSingle(
        uint256 sharesOut,
        uint256[] memory amountsOut,
        uint256 tokenId
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        IVault.ExitPoolRequest
            memory request = _constructExitExactForSingleRequest(
                l,
                amountsOut,
                sharesOut,
                tokenId
            );

        _performExitAndWithdraw(sharesOut, l.poolId, request);
    }

    //TODO: Still WIP to identify how to apply a fee.
    function userWithdrawExactOut(
        uint256 maxSharesIn,
        uint256[] memory minAmountsOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();
        uint256 sharesOut; //NOTE: STILL NEEDS TO BE IDENTIFIED.
        IVault.ExitPoolRequest memory request = _constructExitExactOutRequest(
            l,
            minAmountsOut,
            maxSharesIn
        );

        _performExitAndWithdraw(sharesOut, l.poolId, request);
    }
}

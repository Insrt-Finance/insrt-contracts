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
    function initialize(uint256[] memory amounts, address beneficiary)
        external
    {
        IndexStorage.Layout storage l = IndexStorage.layout();

        bytes memory userData = abi.encode(
            IInvestmentPool.JoinKind.INIT,
            amounts
        );

        _joinPool(amounts, userData);

        _mint(
            beneficiary,
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

        IERC20[] memory tokens = l.tokens;
        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength; ) {
            tokens[i].safeTransferFrom(msg.sender, address(this), amountsIn[i]);
            unchecked {
                ++i;
            }
        }

        uint256 oldSupply = _totalSupply();

        _joinPool(amountsIn, userData);

        uint256 newSupply = IERC20(_asset()).balanceOf(address(this));

        _mint(msg.sender, newSupply - oldSupply);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userWithdrawExactForAll(
        uint256 sharesOut,
        uint256[] calldata minAmountsOut
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

        (uint256 feeBpt, uint256 remainingSharesOut) = _applyFee(
            l.exitFee,
            sharesOut
        );
        bytes memory userData = abi.encode(
            IInvestmentPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT,
            remainingSharesOut
        );

        _exitPool(l, sharesOut, minAmountsOut, userData);
    }

    /**
     * @inheritdoc IIndexIO
     */
    function userWithdrawExactForSingle(
        uint256 sharesOut,
        uint256[] memory minAmountsOut,
        uint256 tokenId
    ) external {
        IndexStorage.Layout storage l = IndexStorage.layout();

        (uint256 feeBpt, uint256 remainingShares) = _applyFee(
            l.exitFee,
            sharesOut
        );

        bytes memory userData = abi.encode(
            IInvestmentPool.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            remainingShares,
            tokenId
        );

        _exitPool(l, sharesOut, minAmountsOut, userData);
    }
}

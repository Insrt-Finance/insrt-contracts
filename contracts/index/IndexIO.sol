// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

import { IIndexIO } from './IIndexIO.sol';
import { IndexInternal } from './IndexInternal.sol';
import { IndexStorage } from './IndexStorage.sol';
import { ISwapper } from './ISwapper.sol';
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
     * @inheritdoc IIndexIO
     */
    function initialize(uint256[] memory poolTokenAmounts, address receiver)
        external
    {
        bytes memory userData = abi.encode(
            IInvestmentPool.JoinKind.INIT,
            poolTokenAmounts
        );

        _joinPool(poolTokenAmounts, userData);

        _mint(
            receiver,
            _previewDeposit(IERC20(_asset()).balanceOf(address(this)))
        );
    }

    /**
     * @inheritdoc IIndexIO
     */
    function collectStreamingFees(address[] calldata accounts) external {
        unchecked {
            for (uint256 i; i < accounts.length; i++) {
                address account = accounts[i];
                _collectStreamingFee(account, _balanceOf(account));
            }
        }
    }

    /**
     * @inheritdoc IIndexIO
     */
    function deposit(
        uint256[] memory poolTokenAmounts,
        uint256 minShareAmount,
        address receiver
    ) external returns (uint256 shareAmount) {
        IndexStorage.Layout storage l = IndexStorage.layout();

        bytes memory userData = abi.encode(
            IInvestmentPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            poolTokenAmounts,
            minShareAmount
        );

        IERC20[] memory tokens = l.tokens;

        uint256 length = tokens.length;

        for (uint256 i; i < length; ) {
            tokens[i].safeTransferFrom(
                msg.sender,
                address(this),
                poolTokenAmounts[i]
            );
            unchecked {
                ++i;
            }
        }

        _joinPool(poolTokenAmounts, userData);

        shareAmount =
            IERC20(_asset()).balanceOf(address(this)) -
            _totalSupply();

        _deposit(
            msg.sender,
            receiver,
            shareAmount,
            shareAmount,
            shareAmount,
            0
        );
    }

    /**
     * @inheritdoc IIndexIO
     */
    function deposit(
        address inputToken,
        uint256 inputTokenAmount,
        address outputToken,
        uint256 outputTokenAmountMin,
        uint256 outputTokenIndex,
        uint256 minShareAmount,
        address target,
        bytes calldata data,
        address receiver
    ) external returns (uint256 shareAmount) {
        IERC20(inputToken).transferFrom(msg.sender, SWAPPER, inputTokenAmount);

        uint256 swapOutputAmount = ISwapper(SWAPPER).swap(
            inputToken,
            inputTokenAmount,
            outputToken,
            outputTokenAmountMin,
            target,
            msg.sender,
            data
        );

        IndexStorage.Layout storage l = IndexStorage.layout();

        uint256[] memory poolTokenAmounts = new uint256[](l.tokens.length);
        poolTokenAmounts[outputTokenIndex] = swapOutputAmount;

        bytes memory userData = abi.encode(
            IInvestmentPool.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT,
            poolTokenAmounts,
            minShareAmount
        );

        _joinPool(poolTokenAmounts, userData);

        shareAmount =
            IERC20(_asset()).balanceOf(address(this)) -
            _totalSupply();

        _deposit(
            msg.sender,
            receiver,
            shareAmount,
            shareAmount,
            shareAmount,
            0
        );
    }

    /**
     * @inheritdoc IIndexIO
     */
    function redeem(
        uint256 shareAmount,
        uint256[] calldata minPoolTokenAmounts,
        address receiver
    ) external returns (uint256[] memory poolTokenAmounts) {
        uint256 assetAmount = _previewRedeem(shareAmount);

        bytes memory userData = abi.encode(
            IInvestmentPool.ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT,
            assetAmount
        );

        poolTokenAmounts = _exitPool(minPoolTokenAmounts, userData, receiver);

        // because assets and shares are pegged 1:1, their difference is equal to fees applied
        uint256 feeAmount = shareAmount - assetAmount;

        // set assetAmount as assetAmountOffset to avoid transferring BPT to receiver
        // set feeAmount as shareAmountOffset to prevent double burn

        _withdraw(
            msg.sender,
            receiver,
            msg.sender,
            assetAmount,
            shareAmount,
            assetAmount,
            feeAmount
        );
    }

    /**
     * @inheritdoc IIndexIO
     */
    function redeem(
        uint256 shareAmount,
        uint256[] memory minPoolTokenAmounts,
        uint256 tokenId,
        address receiver
    ) external returns (uint256 poolTokenAmount) {
        uint256 assetAmount = _previewRedeem(shareAmount);

        bytes memory userData = abi.encode(
            IInvestmentPool.ExitKind.EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
            assetAmount,
            tokenId
        );

        poolTokenAmount = _exitPool(minPoolTokenAmounts, userData, receiver)[
            tokenId
        ];

        // because assets and shares are pegged 1:1, their difference is equal to fees applied
        uint256 feeAmount = shareAmount - assetAmount;

        // set assetAmount as assetAmountOffset to avoid transferring BPT to receiver
        // set feeAmount as shareAmountOffset to prevent double burn

        _withdraw(
            msg.sender,
            receiver,
            msg.sender,
            assetAmount,
            shareAmount,
            assetAmount,
            feeAmount
        );
    }
}

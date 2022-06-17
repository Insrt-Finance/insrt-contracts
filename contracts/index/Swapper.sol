// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ISwapper } from './ISwapper.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { SafeERC20 } from '@solidstate/contracts/utils/SafeERC20.sol';

contract Swapper is ISwapper {
    using SafeERC20 for IERC20;

    /**
     * @inheritdoc ISwapper
     */
    function swap(
        address inputToken,
        address outputToken,
        uint256 outputTokenAmountMin,
        address target,
        bytes calldata data
    ) external {
        IERC20(inputToken).safeApprove(
            target,
            IERC20(inputToken).balanceOf(address(this))
        );

        (bool success, ) = target.call(data);
        require(success, 'Swapper: external swap failed');

        uint256 outputAmount = IERC20(outputToken).balanceOf(address(this));

        require(
            outputAmount >= outputTokenAmountMin,
            'Swapper: output token amount received too small'
        );
        IERC20(outputToken).safeTransfer(msg.sender, outputAmount);
    }
}

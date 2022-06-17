// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { ISwapper } from './ISwapper.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';

contract Swapper is ISwapper {
    /**
     * @inheritdoc ISwapper
     */
    function swap(
        address outputToken,
        uint256 outputTokenAmountMin,
        address target,
        bytes calldata data
    ) external {
        (bool success, ) = target.call(data);
        require(success, 'External swap failed');

        uint256 outputAmount = IERC20(outputToken).balanceOf(address(this));

        require(
            outputAmount >= outputTokenAmountMin,
            'Output token amount received too small'
        );
        IERC20(outputToken).transferFrom(
            address(this),
            msg.sender,
            outputAmount
        );
    }
}

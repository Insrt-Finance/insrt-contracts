// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC4626BaseInternal } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseInternal.sol';

/**
 * @title Infra Index internal functions
 * @dev inherited by all Index implementation contracts
 */
contract IndexInternal is ERC4626BaseInternal {
    /**
     * @inheritdoc ERC4626BaseInternal
     */
    function _totalAssets() internal view override returns (uint256) {
        // TODO: check all positions
        return IERC20(_asset()).balanceOf(address(this));
    }
}

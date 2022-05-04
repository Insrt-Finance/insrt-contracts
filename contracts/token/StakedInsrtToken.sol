// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/ERC20Metadata.sol';
import { ERC4626 } from '@solidstate/contracts/token/ERC4626/ERC4626.sol';
import { ERC4626BaseStorage } from '@solidstate/contracts/token/ERC4626/base/ERC4626BaseStorage.sol';

/**
 * @title Staked INSRT implementation
 * @author Insrt Finance
 * @dev Implementation of StakedInsrtToken accessed via StakedInsrtTokenProxy
 */
contract StakedInsrtToken is ERC4626 {
    using ERC4626BaseStorage for ERC4626BaseStorage.Layout;

    address private immutable INSRT_TOKEN;

    constructor(address insrtToken) {
        ERC4626BaseStorage.layout().asset = insrtToken;

        INSRT_TOKEN = insrtToken;
    }

    /**
     * @inheritdoc ERC20Metadata
     */
    function name() public pure override returns (string memory) {
        return 'Staked INSRT';
    }

    /**
     * @inheritdoc ERC20Metadata
     */
    function symbol() public pure override returns (string memory) {
        return 'xINSRT';
    }

    /**
     * @inheritdoc ERC20Metadata
     */
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function _totalAssets() internal view override returns (uint256) {
        return IERC20(INSRT_TOKEN).balanceOf(address(this));
    }
}

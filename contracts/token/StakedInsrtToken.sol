// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { ERC20 } from '@solidstate/contracts/token/ERC20/ERC20.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/ERC20Metadata.sol';

/**
 * @title Staked INSRT implementation
 * @author Insrt Finance
 * @dev Implementation of StakedInsrtToken accessed via StakedInsrtTokenProxy
 */
contract StakedInsrtToken is ERC20 {
    address private immutable INSRT_TOKEN;

    constructor(address insrtToken) {
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

    function deposit(uint256 amount) external {
        IERC20(INSRT_TOKEN).approve(address(this), amount);

        if (_totalSupply() == 0) {
            _mint(msg.sender, amount);
        } else {
            uint256 mintAmount = (amount * _totalSupply()) /
                IERC20(INSRT_TOKEN).balanceOf(address(this));
            _mint(msg.sender, mintAmount);
        }
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);

        uint256 transferAmount = (amount *
            IERC20(INSRT_TOKEN).balanceOf(address(this))) / _totalSupply();
        IERC20(INSRT_TOKEN).transfer(msg.sender, transferAmount);
    }
}

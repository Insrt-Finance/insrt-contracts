// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { ERC20 } from '@solidstate/contracts/token/ERC20/ERC20.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/ERC20Metadata.sol';

/**
 * @title Insert Finance staking token
 * @author Insert Finance
 * @dev Implementation of XInsert Token accessed via XInsertProxy
 */
contract XInsert is ERC20 {
    address private immutable INSERT_TOKEN;

    constructor(address insertToken) {
        INSERT_TOKEN = insertToken;
    }

    /**
     * @inheritdoc ERC20Metadata
     */
    function name() public pure override returns (string memory) {
        return 'xInsert';
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
        IERC20(INSERT_TOKEN).approve(address(this), amount);

        if (_totalSupply() == 0) {
            _mint(msg.sender, amount);
        } else {
            uint256 mintAmount = (amount * _totalSupply()) /
                IERC20(INSERT_TOKEN).balanceOf(address(this));
            _mint(msg.sender, mintAmount);
        }
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);

        uint256 transferAmount = (amount *
            IERC20(INSERT_TOKEN).balanceOf(address(this))) / _totalSupply();
        IERC20(INSERT_TOKEN).transfer(msg.sender, transferAmount);
    }
}

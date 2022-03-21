// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { ERC20 } from '@solidstate/contracts/token/ERC20/ERC20.sol';
import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { ERC20MetadataStorage } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol';

/**
 * @title Insert Finance staking token
 * @author Insert Finance
 */
contract xInsert is ERC20 {
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;

    IERC20 private immutable INSERT_TOKEN;

    constructor(
        string memory name,
        string memory symbol,
        IERC20 insertToken
    ) {
        ERC20MetadataStorage.Layout
            storage metadataLayout = ERC20MetadataStorage.layout();

        metadataLayout.name = name;
        metadataLayout.symbol = symbol;
        metadataLayout.decimals = 18;

        INSERT_TOKEN = insertToken;
    }

    function deposit(uint256 amount) external {
        INSERT_TOKEN.approve(address(this), amount);

        if (_totalSupply() == 0) {
            _mint(msg.sender, amount);
        } else {
            uint256 mintAmount = (amount * _totalSupply()) /
                INSERT_TOKEN.balanceOf(address(this));
            _mint(msg.sender, mintAmount);
        }
    }

    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);

        uint256 transferAmount = (amount *
            INSERT_TOKEN.balanceOf(address(this))) / _totalSupply();
        INSERT_TOKEN.transfer(msg.sender, transferAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { XInsert } from '../XInsert.sol';

contract XInsertMock is XInsert {
    constructor(
        string memory name,
        string memory symbol,
        IERC20 insertToken
    ) XInsert(name, symbol, insertToken) {}

    function __mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function __burn(address recipient, uint256 amount) external {
        _burn(recipient, amount);
    }
}

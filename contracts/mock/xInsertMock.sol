// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { IERC20 } from '@solidstate/contracts/token/ERC20/IERC20.sol';
import { xInsert } from '../xInsert.sol';

contract xInsertMock is xInsert {
    constructor(
        string memory name,
        string memory symbol,
        IERC20 insertToken
    ) xInsert(name, symbol, insertToken) {}

    function __mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function __burn(address recipient, uint256 amount) external {
        _burn(recipient, amount);
    }
}

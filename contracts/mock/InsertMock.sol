// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Insert } from '../Insert.sol';

contract InsertMock is Insert {
    constructor(string memory name, string memory symbol)
        Insert(name, symbol)
    {}

    function __mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function __burn(address recipient, uint256 amount) external {
        _burn(recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { Insert } from '../Insert.sol';

contract InsertMock is Insert {
    constructor() {}

    function __mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function __burn(address recipient, uint256 amount) external {
        _burn(recipient, amount);
    }
}

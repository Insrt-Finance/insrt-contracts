// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { XInsert } from '../XInsert.sol';

contract XInsertMock is XInsert {
    constructor(address insertToken) XInsert(insertToken) {}

    function __mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function __burn(address recipient, uint256 amount) external {
        _burn(recipient, amount);
    }
}

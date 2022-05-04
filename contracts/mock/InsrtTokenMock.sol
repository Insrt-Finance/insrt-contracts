// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { InsrtToken } from '../token/InsrtToken.sol';

contract InsrtTokenMock is InsrtToken {
    constructor(address holder) InsrtToken(holder) {}

    function __mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function __burn(address recipient, uint256 amount) external {
        _burn(recipient, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.11;

import { StakedInsrtToken } from '../token/StakedInsrtToken.sol';

contract StakedInsrtTokenMock is StakedInsrtToken {
    constructor(address insrtToken) StakedInsrtToken(insrtToken) {}

    function __mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }

    function __burn(address recipient, uint256 amount) external {
        _burn(recipient, amount);
    }
}
